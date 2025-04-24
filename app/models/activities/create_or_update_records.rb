module Activities
  class CreateOrUpdateRecords < Activity
    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

    def requires_batch_config?
      true
    end

    def workflow
      # Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData,
      #   Tasks::ProcessTask, Tasks::TransferTask
      [Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData]
    end

    def data_handler = @data_handler ||=
                         CollectionSpaceMapper.single_record_type_handler_for(self)
  end
end
