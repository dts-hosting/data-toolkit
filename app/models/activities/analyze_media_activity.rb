module Activities
  class AnalyzeMediaActivity < Activity
    include MultiFileRecordType
    include OptList::NoOverride

    def workflow
      []
    end
  end
end
