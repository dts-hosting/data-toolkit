class TaskReconcilerJob < ApplicationJob
  queue_as :high_priority
  limits_concurrency to: 1, key: :task_reconciler, duration: 10.minutes

  GRACE_PERIOD = 15.minutes

  def perform
    Rails.logger.info "Starting TaskReconcilerJob"

    candidates = Task.where(progress_status: Progressable::RUNNING)
      .where.not(started_at: nil)
      .where(started_at: ...GRACE_PERIOD.ago)

    candidates.find_each do |task|
      reconcile(task)
    rescue => e
      Rails.logger.error "TaskReconcilerJob failed for Task #{task.id}: #{e.class} #{e.message}"
    end

    Rails.logger.info "Completed TaskReconcilerJob"
  end

  private

  def reconcile(task)
    return unless task.action_handler

    pending_actions = task.actions.where.not(progress_status: Progressable::COMPLETED)
    return if pending_actions.empty?
    return if live_action_jobs?(task)

    count = pending_actions.count
    Rails.logger.warn "TaskReconcilerJob: Task #{task.id} has #{count} orphaned actions; marking failed"

    pending_actions.find_each do |action|
      feedback = action.feedback_for
      feedback.add_to_errors(
        subtype: :application_error,
        details: "Action job did not complete; marked as failed by reconciler"
      )
      action.done!(feedback)
    end
  end

  # A job is "live" if it still has a chance to run on its own:
  # Ready/Claimed/Scheduled/Blocked. Jobs with a FailedExecution are terminal
  # (exhausted retries) and should not block reconciliation.
  def live_action_jobs?(task)
    SolidQueue::Job
      .where(class_name: task.action_handler.name, finished_at: nil)
      .where.missing(:failed_execution)
      .exists?
  end
end
