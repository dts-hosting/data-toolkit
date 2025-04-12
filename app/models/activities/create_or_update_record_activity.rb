module Activities
  class CreateOrUpdateRecordActivity < Activity
    include OptList::AllowOverride

    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

    def workflow
      # Tasks::FileUploadTask, Tasks::PreProcessTask, Tasks::ProcessTask,
      #   Tasks::TransferTask
      [Tasks::FileUploadTask, Tasks::PreProcessTask]
    end
  end
end
