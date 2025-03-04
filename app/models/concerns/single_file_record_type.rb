module SingleFileRecordType
  extend ActiveSupport::Concern

  included do
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type
      "record_type"
    end
  end
end
