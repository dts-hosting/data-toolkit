module Activities
  class AnalyzeMediaActivity < Activity
    include MultiFileRecordType
    include OptList::NoOverride

    # TODO Eventually needs to be able to run on all site media if no file given
    def workflow
      [Tasks::FileUploadTask]
    end
  end
end
