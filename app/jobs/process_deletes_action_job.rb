# Deletes the CollectionSpace record identified by a data item.
class ProcessDeletesActionJob < ActionJob
  private

  def process(activity, action, feedback)
    delete(activity, action.data_item, feedback)
  end

  # TODO: get the identifier field value from `data_item.data` (the record
  # mapper config provides the identifier field), find the record, make the
  # delete request and add any problems to `feedback`.
  # Offload to a service that can be tested independently (like CheckMediaService):
  #   CollectionSpace::DeleteService.new(
  #     activity.data_handler.client, type: service_path, field: field, value: value
  #   ).perform_with(feedback)
  def delete(activity, data_item, feedback)
    feedback.add_to_errors(subtype: :application_error, details: "#{self.class.name}#delete is not implemented")
  end
end
