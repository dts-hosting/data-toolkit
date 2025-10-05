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
    identifier = data[cfg["identifier_field"].downcase]

    client = handler.client
    response = client.find(
      type: type,
      field: field,
      value: identifier
    )
    unless response.result.success?
      feedback.add_to_errors(subtype: :request_error, details: response.result.errors)
      action.done!(feedback) && return
    end

    begin
      # TODO: what does it look like when media record is found but there is no blob?
      blob_csid = response.parsed["abstract_common_list"]["list_item"]["blobCsid"]
    rescue
      feedback.add_to_warnings(
        subtype: :blob_not_found, details: "#{type} #{field} #{identifier}"
      )
      action.done!(feedback) && return
    end

    # TODO: continue
    Rails.logger.info "blob_csid: #{blob_csid}"

    action.done!
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    action.done!(feedback)
  end
end
