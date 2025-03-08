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
    def create_activity(opts = {})
      opts = {
        user: users(:admin),
        type: "Activities::ExportRecordId"
      }.merge(opts)
      opts[:data_config] = create_data_config_record_type unless opts[:data_config]
      Activity.create(opts)
    end

    def create_data_config_record_type(opts = {})
      opts = {
        config_type: "record_type",
        profile: "core",
        version: "7.0.0",
        record_type: "collectionobject",
        url: "https://example.com/collectionobject-7.0.0.json"
      }.merge(opts)
      DataConfig.create(opts)
    end

    def create_data_config_term_lists(opts = {})
      opts = {
        config_type: "term_lists",
        profile: "core",
        version: "7.0.0",
        url: "https://example.com/vocabularies-7.0.0.json"
      }.merge(opts)
      DataConfig.create(opts)
    end

    def create_data_config_optlist_overrides(opts = {})
      opts = {
        config_type: "optlist_overrides",
        profile: "core",
        url: "https://example.com/optlist.json"
      }.merge(opts)
      DataConfig.create(opts)
    end

    def create_data_items_for_task(task, n = 5)
      n.times do |i|
        task.activity.data_items.create!(
          current_task_id: task.id,
          position: i,
          data: {content: "Data #{i + 1}"}
        )
      end
    end

    def sign_in(user)
      client = user.client
      CollectionSpaceService.stubs(:client_for).returns(client)
      client.stubs(:can_authenticate?).returns(true)
      post session_url, params: {
        cspace_url: user.cspace_url,
        email_address: user.email_address,
        password: user.password
      }
    end

    def sign_in_with_failed_auth(user)
      client = user.client
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
