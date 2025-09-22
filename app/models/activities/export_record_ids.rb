module Activities
  class ExportRecordIds < Activity
    validates :files, presence: false

    def data_config_type = "record_type"

    def workflow
      []
    end

    def self.display_name
      "Export Record IDs"
    end

    def self.file_requirement
      :none
    end

    def self.has_batch_config?
      false
    end

    def self.has_config_fields?
      true
    end
  end
end
