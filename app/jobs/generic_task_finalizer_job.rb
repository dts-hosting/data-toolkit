class GenericTaskFinalizerJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for
    feedback_items = task.data_items.where.not(feedback: nil)

    log_finish && return if feedback_items.empty?

    task.update(feedback: item_feedback_for(feedback, feedback_items))
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.update(feedback: feedback)
  end

  private

  def log_finish
    Rails.logger.info "#{self.class.name} finished"
  end

  def item_feedback_for(feedback, items)
    items.find_each(batch_size: 500) do |item|
      item_feedback = item.feedback_for
      next unless item_feedback.displayable?

      item_feedback.errors.each do |e|
        feedback.add_to_errors(subtype: e.subtype, details: e.details)
      end
      item_feedback.warnings.each do |w|
        feedback.add_to_warnings(subtype: w.subtype, details: w.details)
      end
      item_feedback.messages.each do |m|
        feedback.add_to_messages(subtype: m.subtype, details: m.details)
      end
    end
    feedback
  end
end
