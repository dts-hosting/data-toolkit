class ProcessMediaDerivativesDataItemJob < ApplicationJob
  queue_as :default

  def perform(action)
    action.start!
    data_item = action.data_item
    feedback = data_item.feedback_for

    activity = data_item.activity
    client = activity.data_handler.client

    cfg = Rails.cache.fetch("rm_cfg_for_activity_#{activity.id}", expires_in: 24.hours) do
      activity.data_handler.recordmapper.send(:hash)[:config]
    end

    type = cfg["service_path"]
    field = cfg["identifier_field"]
    identifier = data_item.data[cfg["identifier_field"].downcase]

    response = client.find(
      type: type,
      field: field,
      value: identifier
    )
    unless response.result.success?
      feedback.add_to_errors(subtype: :request_error, details: response.result.errors)
      action.finish!(feedback) && return
    end

    begin
      # TODO: what does it look like when media record is found but there is no blob?
      blob_csid = response.parsed["abstract_common_list"]["list_item"]["blobCsid"]
    rescue
      feedback.add_to_warnings(
        subtype: :blob_not_found, details: "#{type} #{field} #{identifier}"
      )
      action.finish!(feedback) && return
    end

    # TODO: continue
    Rails.logger.info "blob_csid: #{blob_csid}"

    action.finish!
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.finish!(feedback)
  end
end
