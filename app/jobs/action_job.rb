# Base for per-item jobs (a task's action_handler).
# Subclasses implement #process and add to `feedback`; the base guarantees
# the action is always started and completed, including on error.
class ActionJob < ApplicationJob
  queue_as :default

  def perform(activity, action)
    # Re-runs of a completed action are no-ops
    return if action.progress_completed?

    WorkflowManager.start_action(action)
    # Start fresh: a run's results replace, never append to, stored feedback.
    feedback = Feedback.new(action.feedback_context)
    process(activity, action, feedback)
    complete(action, feedback)
  rescue => e
    Rails.logger.error "#{self.class.name} action=#{action.id}: #{e.class} #{e.message}"
    feedback ||= Feedback.new(action.feedback_context)
    feedback.add_to_errors(subtype: :application_error, details: e)
    complete(action, feedback)
  end

  private

  def process(activity, action, feedback)
    raise NotImplementedError, "#{self.class.name} must implement #process"
  end

  # Store nil rather than empty feedback so `where.not(feedback: nil)` (finalizers,
  # reports) only touches actions that have something to say.
  def complete(action, feedback)
    WorkflowManager.complete_action(action, feedback: feedback.displayable? ? feedback : nil)
  end
end
