module Activities
  class CreateOrUpdateRecords < Activity
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}
    validates :config, presence: true

    def data_config_type = "record_type"

    def data_handler = @data_handler ||=
                         CollectionSpaceMapper.single_record_type_handler_for(self)

    def workflow
      # Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData,
      #   Tasks::ProcessTask, Tasks::TransferTask
      [Tasks::ProcessUploadedFiles, Tasks::PreCheckIngestData]
    end

    def self.display_name
      "Create or Update Records"
    end

    def self.file_requirement
      :required_single
    end

    def self.has_batch_config?
      true
    end

    def self.has_config_fields?
      true
    end
  end
end
