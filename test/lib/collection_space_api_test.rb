# test/services/collection_space_service_test.rb
require "test_helper"
require "webmock/minitest"
require "ostruct"

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

  test "blob_data returns blob data from response" do
    response = OpenStruct.new(
      parsed: {
        "document" => {
          "blobs_common" => {
            "name" => "test.jpg",
            "mimeType" => "image/jpeg",
            "length" => "12345"
          }
        }
      }
    )

    blob = CollectionSpaceApi.blob_data(response)
    assert_equal "test.jpg", blob["name"]
    assert_equal "image/jpeg", blob["mimeType"]
    assert_equal "12345", blob["length"]
  end

  test "item_count returns count from response" do
    response = OpenStruct.new(
      parsed: {
        "abstract_common_list" => {
          "itemsInPage" => 5
        }
      }
    )

    assert_equal 5, CollectionSpaceApi.item_count(response)
  end

  test "item_count returns zero when itemsInPage is missing" do
    response = OpenStruct.new(
      parsed: {
        "abstract_common_list" => {}
      }
    )

    assert_equal 0, CollectionSpaceApi.item_count(response)
  end

  test "value_for returns property value from list_item" do
    response = OpenStruct.new(
      parsed: {
        "abstract_common_list" => {
          "list_item" => {
            "csid" => "media-123",
            "blobCsid" => "blob-456"
          }
        }
      }
    )

    assert_equal "media-123", CollectionSpaceApi.value_for(response, "csid")
    assert_equal "blob-456", CollectionSpaceApi.value_for(response, "blobCsid")
  end
end
