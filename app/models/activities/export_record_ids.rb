module Activities
  class ExportRecordIds < Activity
    validates :files, presence: false

    def data_config_type = "record_type"

    def requires_batch_config?
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
