ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "helpers/factory_helpers"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    include FactoryHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in(user)
      client = user.client
      CollectionSpaceApi.stubs(:client_for).returns(client)
      client.stubs(:can_authenticate?).returns(true)
      post session_url, params: {
        cspace_url: user.cspace_url,
        email_address: user.email_address,
        password: user.password
      }
      user
    end

    def sign_in_with_failed_auth(user)
      client = user.client
      CollectionSpaceApi.stubs(:client_for).returns(client)
      client.stubs(:can_authenticate?).returns(false)
      post session_url, params: {
        cspace_url: user.cspace_url,
        email_address: user.email_address,
        password: user.password
      }
    end

    def fixture_file_path(file_name)
      Rails.root.join("test", "fixtures", "files", file_name)
    end

    # @param fixtures [Array<String>] fixture file names
    # @return [ActiveStorage::Attached::Many]
    def fixtures_as_attachments(filenames)
      create_activity({
        type: :check_media_derivatives,
        data_config: create_data_config_record_type(record_type: "media"),
        files: create_uploaded_files(filenames).compact
      }).files
    end
  end
end
