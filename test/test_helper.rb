ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in(user)
      client = CollectionSpace::Client.new
      CollectionSpaceService.stubs(:client_for).returns(client)
      client.stubs(:can_authenticate?).returns(true)
      post session_url, params: {
        cspace_url: user.cspace_url,
        email_address: user.email_address,
        password: user.password
      }
    end

    def sign_in_with_failed_auth(user)
      client = CollectionSpace::Client.new
      CollectionSpaceService.stubs(:client_for).returns(client)
      client.stubs(:can_authenticate?).returns(false)
      post session_url, params: {
        cspace_url: user.cspace_url,
        email_address: user.email_address,
        password: user.password
      }
    end
  end
end
