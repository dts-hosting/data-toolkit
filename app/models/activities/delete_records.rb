module Activities
  class DeleteRecords < Activity
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

    def requires_batch_config?
      true
    end

    def requires_config_fields?
      false
    end

    def requires_files?
      true
    end

    def requires_single_file?
      true
    end

    def select_attributes
      # TODO: [:record_matchpoint]
      []
    end

    # Tasks::DeleteFilePrecheck, Tasks::LookupAndDeleteRecords
    def workflow
      [Tasks::ProcessUploadedFiles]
    end

    def self.display_name
      "Delete Records"
    end
  end
end
