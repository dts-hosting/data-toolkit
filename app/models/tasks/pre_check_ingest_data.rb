# This task handles preprocessing of data items
module Tasks
  class PreCheckIngestData < Task
    def dependencies
      [Tasks::ProcessUploadedFiles]
    end

    def action_handler = PreCheckIngestActionJob
    def finalizer = GenericTaskFinalizerJob
    def handler = PreCheckIngestDataJob

    def self.display_name
      "Pre-Check Ingest Data"
    end
  end
end
