module Activities
  class CheckMediaDerivatives < Activity
    # Takes 0 to many files. Runs on all site media of record_type if no file given

    def data_config_type = "media_record_type"

    def requires_batch_config?
      false
    end

    def requires_config?
      false
    end

    def requires_files?
      true
    end

    def requires_single_file?
      false
    end

    def workflow
      [Tasks::ProcessUploadedFiles]
    end

    def self.display_name
      "Check Media Derivatives"
    end
  end
end
