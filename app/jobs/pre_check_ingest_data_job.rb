class PreCheckIngestDataJob < ApplicationJob
  queue_as :default

  def perform(task)
    task.start!
    Rails.logger.info "#{self.class.name} started"

    feedback = task.feedback_for

    begin
      handler = task.activity.data_handler
    rescue CollectionSpace::Mapper::NoClientServiceError => err
      fail_msg = "collectionspace-client does not have a service configured " \
        "for #{err.message}"
    rescue CollectionSpace::Mapper::IdFieldNotInMapperError
      fail_msg = "cannot determine the unique ID field for this " \
        "record type from DataConfig"
    end

    if fail_msg
      Rails.logger.error fail_msg
      feedback.add_to_errors(subtype: :application_error, details: fail_msg)
      task.fail!(feedback) && return
    end

    first_data_item = task.data_items.first.data
    checker = IngestDataPreCheckFirstItem.new(handler, first_data_item, feedback)
    task.fail!(feedback) && return unless checker.ok?

    task.data_items.without_errors.in_batches(of: 1000) do |batch|
      jobs = batch.map { |data_item| task.data_item_handler.new(data_item) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "#{self.class.name} finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.fail!(feedback)
  end
end
