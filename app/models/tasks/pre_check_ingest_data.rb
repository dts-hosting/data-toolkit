# This task handles preprocessing of data items
module Tasks
  class PreCheckIngestData < Task
    def dependencies
      [Tasks::ProcessUploadedFiles]
    end

    def finalizer = PreCheckIngestDataFinalizerJob

    def handler = PreCheckIngestDataJob

    def self.display_name
      "Pre-Check Ingest Data"
    end
  end
end
