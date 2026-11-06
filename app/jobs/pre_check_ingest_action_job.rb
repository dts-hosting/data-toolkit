class PreCheckIngestActionJob < ActionJob
  private

  def process(activity, action, feedback)
    IngestDataPreCheckItem.new(activity.data_handler, action.data_item.data, feedback).ok?
  end
end
