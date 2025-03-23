module Activities
  class UpdateRecordActivity < Activity
    include SingleFileRecordType
    include OptList::AllowOverride

    def workflow
      []
    end
  end
end
