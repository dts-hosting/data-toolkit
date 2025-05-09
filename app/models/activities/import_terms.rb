module Activities
  class ImportTerms < Activity
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "term_lists"

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
      true
    end

    def workflow
      []
    end

    def self.display_name
      "Import Terms"
    end
  end
end
