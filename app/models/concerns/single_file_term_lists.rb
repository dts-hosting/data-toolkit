module SingleFileTermLists
  extend ActiveSupport::Concern

  included do
    validates :files, presence: true, length: {is: 1, message: "must have exactly one file"}

    def data_config_type
      "term_lists"
    end
  end
end
