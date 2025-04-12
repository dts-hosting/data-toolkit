module Activities
  class DeleteRecordActivity < Activity
    include OptList::NoOverride

    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

    # Tasks::DeleteFilePrecheck, Tasks::LookupAndDeleteRecords
    def workflow
      [Tasks::FileUploadTask]
    end
  end
end
