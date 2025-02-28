class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  encrypts :password

  validates :cspace_url, presence: true,
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "must be a valid URL"
    }
  validates :email_address, presence: true, uniqueness: {scope: :cspace_url}
  validates :password, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_save :format_cspace_url

  def self.can_authenticate?(cspace_url, email_address, password)
    # TODO: authenticate with client
    # url = format_cspace_url(cspace_url)
    true
  end

  def self.format_cspace_url(url)
    url = url.chomp("/")
    unless url.end_with?("/cspace-services")
      url = "#{url}/cspace-services"
    end
    url
  end

  private

  def format_cspace_url
    self.cspace_url = self.class.format_cspace_url(cspace_url)
  end
end
