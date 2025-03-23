module Activities
  class DeleteRecordActivity < Activity
    include SingleFileRecordType
    include OptList::NoOverride

    def workflow
      []
    end
  end
end
