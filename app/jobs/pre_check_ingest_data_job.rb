class PreCheckIngestDataJob < ApplicationJob
  queue_as :default

  def perform(task)
    task.start!
    Rails.logger.info "#{self.class.name} started"

    feedback = task.feedback_for
    activity = task.activity

    begin
      handler = activity.data_handler
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
      task.done!("failed", feedback) && return
    end

    first_data_item = task.data_items.first.data
    checker = IngestDataPreCheckFirstItem.new(handler, first_data_item, feedback)
    task.done!("failed", feedback) && return unless checker.ok?

    task.actions.in_batches(of: 1000) do |batch|
      jobs = batch.map { |action| task.action_handler.new(activity, action) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "#{self.class.name} finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.done!("failed", feedback)
  end
end
