# Single entry point for task/action/activity workflow transitions.
class WorkflowManager
  BULK_INSERT_BATCH_SIZE = 1000

  ##### Task lifecycle

  # Eligibility-gated, single-winner via row lock. Builds actions if the
  # task has an action_handler; enqueues the task's handler job otherwise
  # fails fast with a no-items feedback.
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

  # Terminal task transition. Sets outcome, then advances the activity once.
  # Returns true so callers can use `complete_task(...) && return` patterns.
  def self.complete_task(task, outcome:, feedback: nil)
    activity = task.activity
    transitioned = false

    task.with_lock do
      task.reload
      return true if task.progress_completed?

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
      action.reload
      return true if action.progress_completed?

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

  # Called from Activity#after_create_commit. Starts every task whose type
  # was defined with `auto_trigger true`.
  def self.start_workflow(activity)
    activity.tasks.reload.each do |task|
      run_task(task) if task.task_config&.auto_trigger
    end
    activity.tasks.reset
  end

  # Decides what happens after a task finishes: next task on success-and-enabled,
  # or finalizer + auto-pause otherwise.
  def self.advance_activity(activity)
    task = activity.current_task
    return unless task&.progress_completed?

    if task.outcome_succeeded? && activity.auto_advance_enabled?
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

  def self.build_actions_for(task)
    all_data_items = task.activity.data_items

    errored_items = Action.with_errors
      .where(data_item_id: all_data_items.select(:id))
      .select(:data_item_id)

    processable_items = all_data_items.where.not(id: errored_items)

    now = Time.current
    inserted_count = 0

    processable_items.in_batches(of: BULK_INSERT_BATCH_SIZE) do |batch|
      records = batch.pluck(:id).map do |data_item_id|
        {task_id: task.id, data_item_id: data_item_id, progress_status: Progressable::PENDING,
         created_at: now, updated_at: now}
      end

      result = Action.insert_all(records)
      inserted_count += result.count
    end

    task.update_column(:actions_count, task.actions.count)
    inserted_count
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
