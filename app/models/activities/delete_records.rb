module Activities
  class DeleteRecords < Activity
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "record_type"

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

    def self.file_requirement
      :required_single
    end

    def self.has_batch_config?
      true
    end

    def self.has_config_fields?
      false
    end
  end
end
