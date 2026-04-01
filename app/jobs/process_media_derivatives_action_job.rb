class ProcessMediaDerivativesActionJob < ApplicationJob
  queue_as :default

  def perform(activity, action)
    action.start!
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

    service.perform_with!(action)
  rescue => e
    feedback = action.feedback_for
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.done!(feedback)
  end
end
