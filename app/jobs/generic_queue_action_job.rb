class GenericQueueActionJob < ApplicationJob
  queue_as :default

  def perform(task)
    task.start!
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
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.done!(Task::FAILED, feedback)
  end
end
