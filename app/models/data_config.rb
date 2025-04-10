class DataConfig < ApplicationRecord
  ALLOWED_CONFIG_TYPES = %i[optlist_overrides record_type term_lists].freeze
  URL_FORMAT = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  validates :config_type, presence: true,
    inclusion: {in: ALLOWED_CONFIG_TYPES.map(&:to_s)}
  validates :profile, presence: true
  validates :url, presence: true, format: {with: URL_FORMAT}

  validates :record_type, absence: true, if: -> { optlist_overrides_config? || term_lists_config? }
  validates :record_type, presence: true, if: :record_type_config?

  validates :version, absence: true, if: :optlist_overrides_config?
  validates :version, presence: true, if: -> { record_type_config? || term_lists_config? }

  validate :unique_attributes

  scope :by_profile, ->(user) { where(profile: user.cspace_profile) }
  scope :by_version, ->(user) { where(version: user.cspace_ui_version) }
  scope :optlist_overrides, ->(user) { by_profile(user).with_config_type(:optlist_overrides) }
  scope :record_type, ->(user) { by_profile(user).by_version(user).with_config_type(:record_type) }
  scope :term_lists, ->(user) { by_profile(user).by_version(user).with_config_type(:term_lists) }
  scope :record_type_media, ->(user) { record_type(user).where("record_type LIKE ?", "%media") }

  def optlist_overrides_config?
    matches_config_type?(:optlist_overrides)
  end

  def record_type_config?
    matches_config_type?(:record_type)
  end

  def term_lists_config?
    matches_config_type?(:term_lists)
  end

  def self.for(user, activity)
    send(activity.data_config_type.to_sym, user)
  end

  def self.with_config_type(type)
    where(config_type: type.to_s)
  end

  private

  def matches_config_type?(type)
    config_type == type.to_s
  end

  def unique_attributes
    query = DataConfig.where(
      config_type: config_type,
      profile: profile
    )

    query = query.where(version: version.nil? ? nil : version)
    query = query.where(record_type: record_type.nil? ? nil : record_type)

    if persisted?
      query = query.where.not(id: id)
    end

    if query.exists?
      errors.add(:data_config, "this set of attributes already exists")
    end
  end
end
