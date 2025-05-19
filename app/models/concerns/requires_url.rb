module RequiresUrl
  extend ActiveSupport::Concern
  URL_FORMAT = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  included do
    validates :url, presence: true, format: {with: URL_FORMAT}
  end
end
