module Activities
  class CreateRecordActivity < Activity
    include SingleFileRecordType
    include OptList::AllowOverride

    def workflow
      # Tasks::FileUploadTask, Tasks::PreProcessTask, Tasks::ProcessTask, Tasks::TransferTask
      [Tasks::FileUploadTask, Tasks::PreProcessTask]
    end
  end
end
