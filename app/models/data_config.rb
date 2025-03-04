class DataConfig < ApplicationRecord
  ALLOWED_CONFIG_TYPES = %w[optlist_overrides record_type term_lists].freeze
  URL_FORMAT = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  validates :config_type, presence: true, inclusion: {in: ALLOWED_CONFIG_TYPES}
  validates :profile, presence: true
  validates :record_type, presence: true, if: :record_type_config?
  validates :url, presence: true, format: {with: URL_FORMAT}
  validates :version, presence: true, unless: :optlist_overrides_config?

  scope :optlist_overrides, -> { where(config_type: "optlist_overrides") }
  scope :record_types, -> { where(config_type: "record_type") }
  scope :term_lists, -> { where(config_type: "term_lists") }

  def optlist_overrides_config?
    config_type == "optlist_overrides"
  end

  def record_type_config?
    config_type == "record_type"
  end

  def term_lists_config?
    config_type == "term_lists"
  end
end
