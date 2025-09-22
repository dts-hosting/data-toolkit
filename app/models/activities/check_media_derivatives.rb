module Activities
  class CheckMediaDerivatives < Activity
    validates :files, presence: true, length: {minimum: 1, message: "must have at least one file"}

    def data_config_type = "media_record_type"

    def workflow
      [Tasks::ProcessUploadedFiles]
    end

    def self.display_name
      "Check Media Derivatives"
    end

    def self.file_requirement
      :required_multiple
    end

    def self.has_batch_config?
      false
    end

    def self.has_config_fields?
      false
    end
  end
end
