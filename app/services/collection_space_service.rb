# frozen_string_literal: true

class CollectionSpaceService
  def self.client_for(cspace_url, email_address, password)
    CollectionSpace::Client.new(config_for(cspace_url, email_address, password))
  end

  def self.config_for(cspace_url, email_address, password)
    CollectionSpace::Configuration.new(
      base_uri: format_url(cspace_url),
      username: email_address,
      password: password
    )
  end

  def self.format_url(url)
    url = url.chomp("/")
    unless url.end_with?("/cspace-services")
      url = "#{url}/cspace-services"
    end
    url
  end
end
