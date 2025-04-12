module Activities
  class AnalyzeMediaActivity < Activity
    # Takes 0 to many files. Runs on all site media of record_type if no file
    #   given
    include OptList::NoOverride

    def data_config_type = "record_type"

    def workflow
      [Tasks::FileUploadTask]
    end
  end
end
