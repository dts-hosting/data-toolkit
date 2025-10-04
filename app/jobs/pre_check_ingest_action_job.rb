class PreCheckIngestActionJob < ApplicationJob
  queue_as :default

  def perform(activity, action)
    action.start!
    feedback = action.feedback_for
    handler = activity.data_handler
    data = action.data_item.data

    checker = IngestDataPreCheckItem.new(handler, data, feedback)
    action.finish!(checker.feedback) && return unless checker.ok?

    action.finish!
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.finish!(feedback)
  end
end
