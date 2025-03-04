module NoFileRecordType
  extend ActiveSupport::Concern

  included do
    validates :files, presence: false

    def data_config_type
      "record_type"
    end
  end
end
