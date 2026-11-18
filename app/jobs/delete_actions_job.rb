# Deletes every action belonging to the activity's tasks, to remove
# potentially many rows as soon as the workflow is finished with them.
# Runs as a handler-only task (it has no actions of its own).
class DeleteActionsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 10_000

  def perform(task)
    WorkflowManager.start_task(task)

    Action.where(task_id: task.activity.tasks.select(:id))
      .in_batches(of: BATCH_SIZE)
      .delete_all

    WorkflowManager.complete_task(task, outcome: Task::SUCCEEDED)
  rescue => e
    Rails.logger.error "#{self.class.name} task=#{task.id}: #{e.class} #{e.message}"
    feedback = task.feedback_for
    feedback.add_to_errors(subtype: :application_error, details: e)
    WorkflowManager.complete_task(task, outcome: Task::FAILED, feedback: feedback)
  end
end
