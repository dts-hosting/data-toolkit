class PreCheckIngestDataItemJob < ApplicationJob
  queue_as :default

  def perform(data_item)
    data_item.start!
    feedback = data_item.feedback_for

    checker = IngestDataPreCheckItem.new(
      data_item.activity.data_handler, data_item.data, feedback
    )
    data_item.fail!(checker.feedback) && return unless checker.ok?

    data_item.success!
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    data_item.fail!(feedback)
  end
end
