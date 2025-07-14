class PreCheckIngestDataFinalizerJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for
    item_failures = task.data_items.where(status: "failed")

    if item_failures.empty?
      task.success!
      log_finish && return
    end

    task.fail!(item_failure_feedback_for(feedback, item_failures))
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.fail!(feedback)
  end

  private

  def log_finish
    Rails.logger.info "#{self.class.name} finished"
  end

  def item_failure_feedback_for(feedback, failures)
    failures.each do |item|
      item.feedback_for.errors.each do |err|
        feedback.add_to_errors(subtype: err.subtype, details: err.details)
      end
    end
    feedback
  end
end
