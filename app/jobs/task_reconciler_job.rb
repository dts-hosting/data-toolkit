class TaskReconcilerJob < ApplicationJob
  queue_as :high_priority
  limits_concurrency to: 1, key: :task_reconciler, duration: 10.minutes

  GRACE_PERIOD = 15.minutes

  def perform
    Rails.logger.info "Starting TaskReconcilerJob"

    reconcile_running_tasks
    requeue_stale_queued_tasks

    Rails.logger.info "Completed TaskReconcilerJob"
  end

  private

  def reconcile_running_tasks
    candidates = Task.where(progress_status: Progressable::RUNNING)
      .where.not(started_at: nil)
      .where(started_at: ...GRACE_PERIOD.ago)

    candidates.find_each do |task|
      if task.action_handler
        reconcile_action_task(task)
      else
        reconcile_handler_only_task(task)
      end
    rescue => e
      Rails.logger.error "TaskReconcilerJob failed for Task #{task.id}: #{e.class} #{e.message}"
    end
  end

  # A queued task whose handler job is gone (process died between commit and
  # enqueue, or the job exhausted retries before starting) can never advance
  # on its own. Re-run it; requeue_task/run_task are idempotent.
  def requeue_stale_queued_tasks
    candidates = Task.where(progress_status: Progressable::QUEUED)
      .where(updated_at: ...GRACE_PERIOD.ago)

    candidates.find_each do |task|
      next if live_handler_job?(task)

      Rails.logger.warn "TaskReconcilerJob: Task #{task.id} stuck in queued with no live handler job; re-enqueueing"
      WorkflowManager.requeue_task(task)
    rescue => e
      Rails.logger.error "TaskReconcilerJob failed for Task #{task.id}: #{e.class} #{e.message}"
    end
  end

  def reconcile_action_task(task)
    return if WorkflowManager.finalize_task(task)
    return if live_action_jobs?(task)

    pending_actions = task.actions.where.not(progress_status: Progressable::COMPLETED)
    return if pending_actions.empty?

    Rails.logger.warn "TaskReconcilerJob: Task #{task.id} has #{pending_actions.count} orphaned actions; marking failed"
    pending_actions.find_each { |action| fail_orphan(action) }

    WorkflowManager.finalize_task(task)
  end

  # A handler-only task (no per-item actions) stuck in running means its
  # worker died mid-perform, so the job-level rescue never ran. Fail it so
  # the activity is not stalled forever.
  def reconcile_handler_only_task(task)
    return if live_handler_job?(task)

    Rails.logger.warn "TaskReconcilerJob: Task #{task.id} running with no live handler job; marking failed"
    feedback = task.feedback_for
    feedback.add_to_errors(
      subtype: :application_error,
      details: "Task job did not complete; marked as failed by reconciler"
    )
    WorkflowManager.complete_task(task, outcome: Task::FAILED, feedback: feedback)
  end

  def fail_orphan(action)
    feedback = action.feedback_for
    feedback.add_to_errors(
      subtype: :application_error,
      details: "Action job did not complete; marked as failed by reconciler"
    )
    WorkflowManager.complete_action(action, feedback: feedback)
  end

  # Liveness checks are scoped to the task at hand by matching the
  # serialized GlobalID inside the job's arguments, so unrelated activities
  # running the same job class do not defer reconciliation. Action jobs
  # serialize (activity, action); handler jobs serialize (task).
  def live_action_jobs?(task)
    live_jobs(task.action_handler, task.activity).exists?
  end

  def live_handler_job?(task)
    live_jobs(task.handler, task).exists?
  end

  # A job is "live" if it still has a chance to run on its own:
  # Ready/Claimed/Scheduled/Blocked. Jobs with a FailedExecution are terminal
  # (exhausted retries) and should not block reconciliation.
  def live_jobs(job_class, record)
    gid = ActiveRecord::Base.sanitize_sql_like(record.to_global_id.to_s)
    SolidQueue::Job
      .where(class_name: job_class.name, finished_at: nil)
      .where.missing(:failed_execution)
      .where("arguments LIKE ?", "%#{gid}\"%")
  end
end
