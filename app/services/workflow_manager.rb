# Single entry point for task/action/activity workflow transitions.
class WorkflowManager
  ##### Task lifecycle

  # Eligibility-gated, single-winner via row lock. Builds actions if the
  # task has an action_handler; enqueues the task's handler job, or fails
  # fast with a no-items feedback when the task ends up with no actions.
  def self.run_task(task)
    return unless task.ok_to_run?

    enqueue = false
    fail_no_items = false
    task.with_lock do
      next unless task.ok_to_run?

      if task.action_handler && build_actions_for(task).zero?
        fail_no_items = true
      else
        task.update!(progress_status: Progressable::QUEUED)
        enqueue = true
      end
    end

    if fail_no_items
      complete_task(task, outcome: Task::FAILED, feedback: no_items_feedback(task))
    elsif enqueue
      task.handler.perform_later(task)
    end
  end

  def self.start_task(task)
    task.update!(progress_status: Progressable::RUNNING, started_at: Time.current)
  end

  # Recovery path for a task stuck in "queued" (its handler job was lost
  # before it could start). Resets to pending under the lock, then re-runs.
  # Safe to repeat: run_task is single-winner and action building keeps
  # existing rows.
  def self.requeue_task(task)
    reset = false
    task.with_lock do
      next unless task.progress_queued? && task.started_at.nil?

      task.update!(progress_status: Progressable::PENDING)
      reset = true
    end
    run_task(task) if reset
  end

  # Terminal task transition. Sets outcome, then advances the activity once.
  # Returns true so callers can use `complete_task(...) && return` patterns.
  def self.complete_task(task, outcome:, feedback: nil)
    activity = task.activity
    transitioned = false

    task.with_lock do
      next if task.progress_completed?

      task.update!(
        progress_status: Progressable::COMPLETED,
        outcome_status: outcome,
        completed_at: Time.current,
        feedback: feedback
      )
      transitioned = true
    end

    advance_activity(activity) if transitioned
    true
  end

  ##### Action lifecycle

  def self.start_action(action)
    action.update!(progress_status: Progressable::RUNNING, started_at: Time.current)
  end

  # Terminal action transition. Marks the action complete, atomically bumps
  # the parent task's counter, and finalizes the task when the last action
  # lands. Returns true so callers can use `complete_action(...) && return`.
  def self.complete_action(action, feedback: nil)
    transitioned = false

    action.with_lock do
      next if action.progress_completed?

      action.update!(
        progress_status: Progressable::COMPLETED,
        completed_at: Time.current,
        feedback: feedback
      )
      transitioned = true
    end

    return true unless transitioned

    row = atomic_increment_completed(action.task)
    return true if row.nil?

    if row["actions_completed_count"] == row["actions_count"]
      finalize_task(action.task)
    elsif rand < action.task.checkin_frequency
      broadcast_progress(action, row)
    end
    true
  end

  ##### Activity entry points

  # Called from Activity#after_create_commit. Starts the first task.
  def self.start_workflow(activity)
    first_task_type = activity.workflow.first
    first_task = activity.tasks.find_by(type: first_task_type.to_s) if first_task_type
    run_task(first_task) if first_task
    activity.tasks.reset
  end

  # Decides what happens after a task finishes: next task on success-and-enabled,
  # or finalizer + auto-pause otherwise. The finalizer (feedback aggregation)
  # is skipped on success deliberately: a succeeded task has no action
  # feedback to aggregate.
  def self.advance_activity(activity)
    activity.tasks.reset
    task = activity.current_task
    return unless task&.progress_completed?

    if task.outcome_succeeded? && activity.auto_advance_configured?
      activity.resume_auto_advance!
      run_next(activity)
    else
      task.finalizer&.perform_later(task)
      activity.pause_auto_advance!
    end
  end

  # Manual "Advance" button. Always runs the next task regardless of
  # outcome and resumes auto-advance for the rest of the workflow.
  def self.advance_manually(activity)
    activity.tasks.reset
    return unless activity.current_task&.progress_completed?
    activity.resume_auto_advance!
    run_next(activity)
  end

  ##### Reconciliation

  # Recompute counts under the lock so a drifted cache cannot force a false
  # finalize, then commit the terminal transition. Public so TaskReconcilerJob
  # can call it as a recovery path. Returns true if the task transitioned to
  # completed, false otherwise.
  def self.finalize_task(task)
    activity = task.activity
    finalized = false
    task.with_lock do
      task.update_columns(
        actions_count: task.actions.count,
        actions_completed_count: task.actions.progress_completed.count
      )
      next unless task.progress_running?
      next unless task.actions_count.positive?
      next unless task.actions_completed_count >= task.actions_count

      task.update!(
        progress_status: Progressable::COMPLETED,
        outcome_status: computed_outcome(task),
        completed_at: Time.current
      )
      finalized = true
    end
    advance_activity(activity) if finalized
    finalized
  end

  ##### private

  def self.computed_outcome(task)
    error_count = task.actions.with_errors.count
    return Task::FAILED if error_count == task.actions_count
    return Task::REVIEW if error_count > 0 || task.actions.with_warnings.exists?
    Task::SUCCEEDED
  end

  def self.atomic_increment_completed(task)
    Task.connection.select_one(
      Task.sanitize_sql([
        "UPDATE tasks SET actions_completed_count = actions_completed_count + 1, " \
        "updated_at = NOW() " \
        "WHERE id = ? AND progress_status != ? " \
        "AND actions_completed_count < actions_count " \
        "RETURNING actions_completed_count, actions_count",
        task.id, Progressable::COMPLETED
      ])
    )
  end

  # Builds pending actions for the task's processable data items (items
  # whose prior actions errored are skipped) in a single INSERT ... SELECT,
  # keeping the lock in run_task short. Re-runs are safe: existing rows are
  # kept (ON CONFLICT DO NOTHING). Returns the total number of actions on
  # the task, not the number inserted, so a re-run is not considered "no items".
  def self.build_actions_for(task)
    all_data_items = task.activity.data_items

    errored_items = Action.with_errors
      .where(data_item_id: all_data_items.select(:id))
      .select(:data_item_id)

    select_sql = all_data_items
      .where.not(id: errored_items)
      .select(Task.sanitize_sql([
        "? AS task_id, data_items.id AS data_item_id, ? AS progress_status, NOW(), NOW()",
        task.id, Progressable::PENDING
      ]))
      .to_sql

    Action.connection.execute(
      "INSERT INTO actions (task_id, data_item_id, progress_status, created_at, updated_at) " \
      "#{select_sql} ON CONFLICT (task_id, data_item_id) DO NOTHING"
    )

    task.update_column(:actions_count, task.actions.count)
    task.actions_count
  end

  def self.broadcast_progress(action, row)
    count = row["actions_completed_count"]
    total = row["actions_count"]
    progress = total.positive? ? ((count.to_f / total) * 100).round : 0
    action.broadcast_action_to(
      action.task,
      action: :update,
      partial: "shared/card/progress",
      locals: {property: "Progress", value: progress},
      target: "task_#{action.task.id}_progress"
    )
  end

  def self.no_items_feedback(task)
    feedback = task.feedback_for
    feedback.add_to_errors(
      subtype: :application_error,
      details: "Task could not be queued because there were no processable items."
    )
    feedback
  end

  def self.run_next(activity)
    nxt = activity.next_task
    run_task(nxt) if nxt
  end

  private_class_method :computed_outcome, :atomic_increment_completed,
    :build_actions_for, :broadcast_progress, :no_items_feedback, :run_next
end
