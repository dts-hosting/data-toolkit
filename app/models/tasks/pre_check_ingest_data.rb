# This task handles preprocessing of data items
module Tasks
  class PreCheckIngestData < Task
    def dependencies
      [Tasks::ProcessUploadedFiles]
    end

    def finalizer = GenericTaskFinalizerJob
    def handler = PreCheckIngestDataJob
    def data_item_handler = PreCheckIngestDataItemJob

    def self.display_name
      "Pre-Check Ingest Data"
    end
  end
end
