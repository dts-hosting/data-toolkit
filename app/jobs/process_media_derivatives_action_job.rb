class ProcessMediaDerivativesActionJob < ApplicationJob
  queue_as :default

  def perform(activity, action)
    action.start!
    feedback = action.feedback_for
    handler = activity.data_handler
    data = action.data_item.data

    cfg = Rails.cache.fetch("rm_cfg_for_activity_#{activity.id}", expires_in: 24.hours) do
      handler.recordmapper.send(:hash)[:config]
    end

    type = cfg["service_path"]
    field = cfg["identifier_field"]
    identifier = data[field.downcase].to_s

    service = CollectionSpace::CheckMediaService.new(
      handler.client, type: type, field: field, value: identifier
    )

    begin
      service.retrieve_data
    rescue => e
      feedback.add_to_errors(subtype: :request_error, details: "#{service.name} - #{e.message}")
      action.done!(feedback) && return
    end

    unless service.is_derivable?
      action.done! && return
    end

    unless service.verify?
      feedback.add_to_errors(subtype: :derivative_count_mismatch, details: service.blob)
      action.done!(feedback) && return
    end

    action.done!
  rescue => e
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.done!(feedback)
  end
end
