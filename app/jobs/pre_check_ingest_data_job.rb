class PreCheckIngestDataJob < GenericQueueActionJob
  private

  def ready?(task, feedback)
    handler = task.activity.data_handler
    IngestDataPreCheckFirstItem.new(handler, task.data_items.first.data, feedback).ok?
  rescue CollectionSpace::Mapper::NoClientServiceError => e
    fail_with(feedback, "collectionspace-client does not have a service configured for #{e.message}")
  rescue CollectionSpace::Mapper::IdFieldNotInMapperError
    fail_with(feedback, "cannot determine the unique ID field for this record type from DataConfig")
  end

  def fail_with(feedback, msg)
    feedback.add_to_errors(subtype: :application_error, details: msg)
    false
  end
end
