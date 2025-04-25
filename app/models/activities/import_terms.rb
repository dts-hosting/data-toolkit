module Activities
  class ImportTerms < Activity
    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "term_lists"

    def requires_batch_config?
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
