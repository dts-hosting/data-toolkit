class ProcessMediaDerivativesActionJob < ActionJob
  private

  def process(activity, action, feedback)
    handler = activity.data_handler
    cfg = Rails.cache.fetch("cfg_for_activity_#{activity.id}", expires_in: 24.hours) do
      handler.recordmapper.send(:hash)[:config]
    end

    field = cfg["identifier_field"]
    service = CollectionSpace::CheckMediaService.new(
      handler.client,
      type: cfg["service_path"],
      field: field,
      value: action.data_item.data[field.downcase].to_s
    )
    service.perform_with(feedback)
  end
end
