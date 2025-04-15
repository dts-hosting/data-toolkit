module Activities
  class ImportTermActivity < Activity
    validates :files, presence: true,
      length: {is: 1, message: "must have exactly one file"}

    def data_config_type = "term_lists"

    def workflow
      []
    end
  end
end
