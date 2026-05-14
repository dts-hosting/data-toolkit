class PreCheckIngestActionJob < ApplicationJob
  queue_as :default

  def perform(activity, action)
    WorkflowManager.start_action(action)
    feedback = action.feedback_for
    handler = activity.data_handler
    data = action.data_item.data

    checker = IngestDataPreCheckItem.new(handler, data, feedback)
    WorkflowManager.complete_action(action, feedback: checker.feedback) && return unless checker.ok?

    WorkflowManager.complete_action(action)
  rescue => e
    Rails.logger.error e.message
    feedback ||= action.feedback_for
    feedback.add_to_errors(subtype: :application_error, details: e)
    WorkflowManager.complete_action(action, feedback: feedback)
  end
end
