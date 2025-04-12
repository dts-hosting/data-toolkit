module Activities
  class ExportRecordId < Activity
    include OptList::NoOverride

    validates :files, presence: false

    def data_config_type = "record_type"

    def workflow
      []
    end
  end
end
