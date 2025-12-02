# frozen_string_literal: true

module CollectionSpaceApi
  class << self
    def blob_data(response)
      ResponseWrapper.new(response).blob_data
    end

    def client_for(cspace_url, email_address, password)
      CollectionSpace::Client.new(config_for(cspace_url, email_address, password))
    end

    def config_for(cspace_url, email_address, password)
      CollectionSpace::Configuration.new(
        base_uri: format_url(cspace_url),
        username: email_address,
        password: password
      )
    end

    def format_url(url)
      url = url.chomp("/")
      unless url.end_with?("/cspace-services")
        url = "#{url}/cspace-services"
      end
      url
    end

    def item_count(response)
      ResponseWrapper.new(response).item_count
    end

    def value_for(response, property)
      ResponseWrapper.new(response).value_for(property)
    end
  end

  class ResponseWrapper
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def blob_data
      response.parsed["document"]["blobs_common"]
    end

    def item_count
      response.parsed["abstract_common_list"].fetch("itemsInPage", 0).to_i
    end

    def value_for(property)
      response.parsed["abstract_common_list"]["list_item"][property]
    end
  end
end
