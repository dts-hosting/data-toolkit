class PreCheckIngestActionJob < ApplicationJob
  queue_as :default

  def perform(action)
    action.start!
    data_item = action.data_item
    feedback = data_item.feedback_for

    checker = IngestDataPreCheckItem.new(
      data_item.activity.data_handler, data_item.data, feedback
    )
    action.finish!(checker.feedback) && return unless checker.ok?

    action.finish!
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.finish!(feedback)
  end
end
