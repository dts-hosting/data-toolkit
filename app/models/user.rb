# Represents a user in the system with CollectionSpace integration
class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  encrypts :password

  validates :cspace_url, presence: true, length: {maximum: 2048},
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "must be a valid URL"
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

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_save :format_cspace_url

  # Returns a CollectionSpace client instance for the user
  # @return [CollectionSpace::Client]
  def client
    CollectionSpaceService.client_for(cspace_url, email_address, password)
  end

  private

  def format_cspace_url
    self.cspace_url = CollectionSpaceService.format_url(cspace_url)
  end
end
