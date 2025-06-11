module Activities
  class ExportRecordIds < Activity
    validates :files, presence: false

    def data_config_type = "record_type"

    def requires_batch_config?
      false
    end

    def requires_config_fields?
      true
    end

    def requires_files?
      false
    end

    def requires_single_file?
      false
    end

    def workflow
      []
    end

    def self.display_name
      "Export Record IDs"
    end
  end
end
