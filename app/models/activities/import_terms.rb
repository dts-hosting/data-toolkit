module Activities
  class ImportTerms < Activity
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "term_list"

    def workflow
      []
    end

    def self.display_name
      "Import Terms"
    end

    def self.file_requirement
      :required_single
    end

    def self.has_batch_config?
      false
    end

    def self.has_config_fields?
      false
    end
  end
end
