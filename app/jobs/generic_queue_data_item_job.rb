class GenericQueueDataItemJob < ApplicationJob
  queue_as :default

  def perform(task)
    task.start!
    Rails.logger.info "#{self.class.name} started"

    feedback = task.feedback_for

    task.data_items.in_batches(of: 1000) do |batch|
      jobs = batch.map { |data_item| task.data_item_handler.new(data_item) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "#{self.class.name} finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.fail!(feedback)
  end
end
