module MultiFileRecordType
  extend ActiveSupport::Concern

  included do
    validates :files, presence: true

    def data_config_type
      "record_type"
    end
  end
end
