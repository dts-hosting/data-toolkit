class GenericTaskFinalizerJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for
    feedback_actions = task.actions.where.not(feedback: nil)

    log_finish && return if feedback_actions.empty?

    task.update(feedback: action_feedback_for(feedback, feedback_actions))
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.update(feedback: feedback)
  end

  private

  def action_feedback_for(feedback, actions)
    actions.find_each(batch_size: 500) do |action|
      action_feedback = action.feedback_for
      next unless action_feedback.displayable?

      feedback + action_feedback
    end
    feedback
  end
end
