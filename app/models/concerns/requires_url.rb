module RequiresUrl
  extend ActiveSupport::Concern

  URL_FORMAT = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  included do
    validates :url, presence: true, format: {with: URL_FORMAT}

    def name_for_url
      url.split("/")[-1]
    end
  end
end
