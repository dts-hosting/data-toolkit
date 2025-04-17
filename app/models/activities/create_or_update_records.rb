module Activities
  class CreateOrUpdateRecords < Activity
    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

    def workflow
      # Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData,
      #   Tasks::ProcessTask, Tasks::TransferTask
      [Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData]
    end
  end
end
