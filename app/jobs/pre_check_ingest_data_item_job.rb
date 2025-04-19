class PreCheckIngestDataItemJob < ApplicationJob
  queue_as :default

  def perform(data_item)
    data_item.start!

    checker = IngestDataPreCheckItem.new(
      data_item.activity.data_handler, data_item.data
    )
    data_item.fail!(checker.feedback) && return unless checker.ok?

    data_item.success!
  rescue => e
    Rails.logger.error e.message
    data_item.fail!({errors: {"application error" => [e.message]}})
  end
end
