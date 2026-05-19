class DataConfig < ApplicationRecord
  include RequiresUrl

  PROFILE_VERSION_CONFIG_TYPES = %w[record_type term_list].freeze

  ProfileVersionOption = Struct.new(:id, :profile, :version) do
    def display_name
      "#{profile} #{version}"
    end
  end

  has_many :activities, dependent: :restrict_with_exception
  belongs_to :manifest, counter_cache: true

  enum :config_type, {optlist_override: "optlist_override", record_type: "record_type", term_list: "term_list"}

  validates :config_type, presence: true
  validates :profile, presence: true

  validates :record_type, absence: true, if: -> { optlist_override? || term_list? }
  validates :record_type, presence: true, if: :record_type?

  validates :version, absence: true, if: :optlist_override?
  validates :version, presence: true, if: -> { record_type? || term_list? }

  validate :unique_attributes

  before_save -> { self.config_type = config_type.singularize }

  scope :by_config_type, ->(config_type) { where(config_type: config_type.to_s) }
  scope :by_profile, ->(user) { where(profile: user.effective_cspace_profile) }
  scope :by_version, ->(user) { where(version: user.effective_cspace_ui_version) }
  scope :media_record_type, ->(user) { record_type(user).where("record_type ILIKE ?", "%media%") }
  scope :optlist_override, ->(user) { by_profile(user).by_config_type(:optlist_override) }
  scope :record_type, ->(user) { by_profile(user).by_version(user).by_config_type(:record_type) }
  scope :term_list, ->(user) { by_profile(user).by_version(user).by_config_type(:term_list) }

  def display_name
    "#{profile} #{version} #{record_type}".strip
  end

  def self.for(user, activity)
    send(activity.data_config_type.to_sym, user)
  end

  def self.profile_version_options
    where(config_type: PROFILE_VERSION_CONFIG_TYPES)
      .select("MIN(id) AS id, profile, version")
      .group(:profile, :version)
      .order(:profile, :version)
      .map do |data_config|
        ProfileVersionOption.new(data_config.id, data_config.profile, data_config.version)
      end
      .sort do |left, right|
        profile_sort = left.profile <=> right.profile
        profile_sort.zero? ? Gem::Version.new(right.version) <=> Gem::Version.new(left.version) : profile_sort
      end
  end

  private

  def unique_attributes
    query = DataConfig.where(
      manifest_id: manifest_id,
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
