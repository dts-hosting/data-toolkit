module Tasks
  class ProcessMediaDerivatives < Task
    def dependencies
      [Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData]
    end

    def finalizer = nil # ProcessMediaDerivativesReportJob
    def handler = GenericQueueDataItemJob
    def data_item_handler = ProcessMediaDerivativesDataItemJob

    def self.display_name
      "Process Media Derivatives"
    end
  end
end
