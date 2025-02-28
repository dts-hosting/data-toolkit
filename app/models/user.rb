class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  encrypts :password

  validates :cspace_url, presence: true,
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "must be a valid URL"
    }
  validates :email_address, presence: true, uniqueness: {scope: :cspace_url}
  validates :cspace_api_version, :cspace_profile, :cspace_ui_version, presence: true
  validates :password, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_save :format_cspace_url

  def client
    CollectionSpaceService.client_for(cspace_url, email_address, password)
  end

  private

  def format_cspace_url
    self.cspace_url = CollectionSpaceService.format_url(cspace_url)
  end
end
