class GenericQueueActionJob < ApplicationJob
  queue_as :default

  def perform(task)
    WorkflowManager.start_task(task)
    Rails.logger.info "#{self.class.name} started"

    feedback = task.feedback_for
    activity = task.activity

    task.actions.in_batches(of: 1000) do |batch|
      jobs = batch.map { |action| task.action_handler.new(activity, action) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "#{self.class.name} finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    feedback ||= task.feedback_for
    feedback.add_to_errors(subtype: :application_error, details: e)
    WorkflowManager.complete_task(task, outcome: Task::FAILED, feedback: feedback)
  end
end
