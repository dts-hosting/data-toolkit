class Activities::CreateRecordActivity < Activity
  include SingleFileRecordType
  include OptList::AllowOverride

  def workflow
    # Tasks::FileUploadTask, Tasks::PreProcessTask, Tasks::ProcessTask, Tasks::TransferTask
    []
  end
end
