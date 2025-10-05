module Tasks
  class ProcessMediaDerivatives < Task
    def dependencies
      [Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData]
    end

    def action_handler = ProcessMediaDerivativesActionJob
    def finalizer = nil # ProcessMediaDerivativesReportJob
    def handler = GenericQueueActionJob

    def self.display_name
      "Process Media Derivatives"
    end
  end
end
