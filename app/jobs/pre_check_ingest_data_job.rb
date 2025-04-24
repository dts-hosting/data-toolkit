class PreCheckIngestDataJob < ApplicationJob
  queue_as :default

  # This job spawns a sub-job for each data item
  def perform(task)
    task.start!
    Rails.logger.info "#{self.class.name} started"

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
      task.fail!({errors: {"application error" => [fail_msg]}}) && return
    end

    first_data_item = task.data_items.first.data
    checker = IngestDataPreCheckFirstItem.new(handler, first_data_item)
    task.fail!(checker.feedback) && return unless checker.ok?

    task.data_items.in_batches(of: 1000) do |batch|
      jobs = batch.map { |data_item| PreCheckIngestDataItemJob.new(data_item) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "#{self.class.name} finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    task.fail!({errors: [e.message]})
  end
end
