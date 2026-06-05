# Represents a user in the system with CollectionSpace integration
class User < ApplicationRecord
  attr_accessor :profile_version_data_config_id

  has_many :activities, dependent: :destroy
  has_many :sessions, dependent: :destroy
  encrypts :password

  validates :cspace_url, presence: true, length: {maximum: 2048},
    format: {
      with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}.*\/cspace-services\z/,
      message: "must be a valid URL ending with /cspace-services"
    }

  validates :email_address, presence: true, uniqueness: {scope: :cspace_url},
    format: {
      with: URI::MailTo::EMAIL_REGEXP,
      message: "must be a valid email address"
    }

  with_options presence: true do
    validates :cspace_api_version, :cspace_profile, :cspace_ui_version
    validates :password, length: {minimum: 8}
  end

  validate :profile_version_override_pair

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def admin?
    Rails.configuration.admin_emails.include?(email_address)
  end

  def effective_cspace_profile
    cspace_profile_override.presence || cspace_profile
  end

  def effective_cspace_ui_version
    cspace_ui_version_override.presence || cspace_ui_version
  end

  def cspace_profile_version_overridden?
    cspace_profile_override.present? && cspace_ui_version_override.present?
  end

  # Returns a CollectionSpace client instance for the user
  # @return [CollectionSpace::Client]
  def client
    CollectionSpaceApi.client_for(cspace_url, email_address, password)
  end

  def is?(user)
    id == user&.id
  end

  private

  def profile_version_override_pair
    return if cspace_profile_override.blank? && cspace_ui_version_override.blank?
    return if cspace_profile_override.present? && cspace_ui_version_override.present?

    errors.add(:base, "Profile and UI version override must be set together")
  end
end
