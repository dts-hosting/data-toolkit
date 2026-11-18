# Sends a data item's previously generated XML (its payload) to CollectionSpace
# as a create or update request, according to the activity's configured action.
class ProcessTransfersActionJob < ActionJob
  private

  def process(activity, action, feedback)
    data_item = action.data_item
    unless data_item.payload.attached?
      feedback.add_to_errors(subtype: :payload_missing, details: "data item #{data_item.position}")
      return
    end

    transfer(activity, data_item, feedback)
  end

  # TODO: make the create or update request (activity.config["action"]) and
  # add any request/response problems to `feedback`.
  # Offload to a service that can be tested independently (like CheckMediaService):
  #   CollectionSpace::TransferService.new(
  #     activity.data_handler.client,
  #     action: activity.config["action"],
  #     xml: data_item.payload.download
  #   ).perform_with(feedback)
  def transfer(activity, data_item, feedback)
    feedback.add_to_errors(subtype: :application_error, details: "#{self.class.name}#transfer is not implemented")
  end
end
