# Generates the CollectionSpace XML for a data item and stores it as the
# item's payload, so that every item is prepared before any transfer is
# attempted (see ProcessTransfersActionJob).
class PrepareTransfersActionJob < ActionJob
  private

  def process(activity, action, feedback)
    data_item = action.data_item
    xml = generate_xml(activity.data_handler, data_item.data, feedback)
    return unless feedback.ok?

    data_item.payload.attach(
      io: StringIO.new(xml),
      filename: "#{data_item.id}.xml",
      content_type: "application/xml"
    )
  end

  # TODO: map `data` to CollectionSpace XML using the data handler. Add any
  # mapping problems to `feedback`. If the csid/uri lookup for updates happens
  # here, it will need to be stored alongside the payload.
  # Offload to a service that can be tested independently (like CheckMediaService):
  #   generator = CollectionSpace::XMLGenerator.new(handler, data)
  #   generator.perform_with(feedback)
  #   generator.xml
  def generate_xml(handler, data, feedback)
    feedback.add_to_errors(subtype: :application_error, details: "#{self.class.name}#generate_xml is not implemented")
    nil
  end
end
