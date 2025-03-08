# test/services/collection_space_service_test.rb
require "test_helper"
require "webmock/minitest"

class CollectionSpaceApiTest < ActiveSupport::TestCase
  test "format_url removes trailing slash" do
    url = "https://cs.collectionspace.org/"
    assert_equal "https://cs.collectionspace.org/cspace-services", CollectionSpaceApi.format_url(url)
  end

  test "format_url adds cspace-services if missing" do
    url = "https://cs.collectionspace.org"
    assert_equal "https://cs.collectionspace.org/cspace-services", CollectionSpaceApi.format_url(url)
  end

  test "format_url preserves existing cspace-services path" do
    url = "https://cs.collectionspace.org/cspace-services"
    assert_equal "https://cs.collectionspace.org/cspace-services", CollectionSpaceApi.format_url(url)
  end

  test "format_url removes trailing slash from cspace-services" do
    url = "https://cs.collectionspace.org/cspace-services/"
    assert_equal "https://cs.collectionspace.org/cspace-services", CollectionSpaceApi.format_url(url)
  end
end
