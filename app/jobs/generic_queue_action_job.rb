# Handler for tasks with an action_handler: starts the task, runs optional
# up-front checks, then fans out one action job per action. The task is
# finalized by WorkflowManager when the last action completes.
class GenericQueueActionJob < ApplicationJob
  queue_as :default

  def perform(task)
    WorkflowManager.start_task(task)
    feedback = task.feedback_for

    unless ready?(task, feedback)
      WorkflowManager.complete_task(task, outcome: Task::FAILED, feedback: feedback)
      return
    end

    queue_actions(task)
  rescue => e
    Rails.logger.error "#{self.class.name} task=#{task.id}: #{e.class} #{e.message}"
    feedback ||= task.feedback_for
    feedback.add_to_errors(subtype: :application_error, details: e)
    WorkflowManager.complete_task(task, outcome: Task::FAILED, feedback: feedback)
  end

  private

  # Override for task-level checks. Add errors to `feedback` and return false to fail the task.
  def ready?(task, feedback) = true

  def queue_actions(task)
    activity = task.activity
    task.actions.in_batches(of: 1000) do |batch|
      ActiveJob.perform_all_later(batch.map { |action| task.action_handler.new(activity, action) })
    end
  end
end
