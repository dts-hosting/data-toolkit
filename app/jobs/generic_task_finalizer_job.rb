class GenericTaskFinalizerJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for
    feedback_actions = task.actions.where.not(feedback: nil)

    log_finish && return if feedback_actions.empty?

    task.update(feedback: item_feedback_for(feedback, feedback_actions))
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

      feedback + item_feedback
    end
    feedback
  end
end
