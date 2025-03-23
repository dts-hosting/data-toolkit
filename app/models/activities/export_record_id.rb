module Activities
  class ExportRecordId < Activity
    include NoFileRecordType
    include OptList::NoOverride

    def workflow
      []
    end
  end
end
