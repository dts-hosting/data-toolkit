require "test_helper"
require "minitest/mock"
require "ostruct"

module CollectionSpace
  class CheckMediaServiceTest < ActiveSupport::TestCase
    def setup
      @opts = {type: "media", field: "identificationNumber", value: "TEST123"}
      @service = CheckMediaService.new(nil, @opts)
    end

    test "valid? returns true for media type" do
      service = CheckMediaService.new(nil, {type: "media", field: "id", value: "123"})
      assert service.valid?
    end

    test "valid? returns true for restricted_media type" do
      service = CheckMediaService.new(nil, {type: "restricted_media", field: "id", value: "123"})
      assert service.valid?
    end

    test "valid? returns false for invalid type" do
      service = CheckMediaService.new(nil, {type: "invalid", field: "id", value: "123"})
      refute service.valid?
    end

    test "is_derivable? returns true when blob has csid and derivable mime type" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.mime_type = "image/jpeg"
      assert service.is_derivable?
    end

    test "is_derivable? returns false when blob has no csid" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = nil
      service.blob.mime_type = "image/jpeg"
      refute service.is_derivable?
    end

    test "is_derivable? returns false when mime type not derivable" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.mime_type = "application/pdf"
      refute service.is_derivable?
    end

    test "has_derivatives? returns true when derivatives count is positive" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.derivatives_count = 5
      assert service.has_derivatives?
    end

    test "has_derivatives? returns false when derivatives count is zero" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.derivatives_count = 0
      refute service.has_derivatives?
    end

    test "has_all_derivatives? returns true when count matches expected" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.derivatives_count = CheckMediaService::EXPECTED_DERIVABLE_COUNT
      assert service.has_all_derivatives?
    end

    test "has_all_derivatives? returns false when count does not match expected" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.derivatives_count = 3
      refute service.has_all_derivatives?
    end

    test "verify? returns true when has all derivatives" do
      service = CheckMediaService.new(nil, @opts)
      service.blob.csid = "blob-123"
      service.blob.derivatives_count = CheckMediaService::EXPECTED_DERIVABLE_COUNT
      assert service.verify?
    end

    test "retrieve_data successfully retrieves all data" do
      @service.stub :get_media_record, media_response do
        @service.stub :get_blob_record, blob_response do
          @service.stub :get_derivatives_record, derivatives_response do
            @service.retrieve_data

            assert_equal "blob-csid-123", @service.blob.csid
            assert_equal "media-csid-456", @service.blob.media_csid
            assert_equal "1234567", @service.blob.length
            assert_equal "abc123def", @service.blob.digest
            assert_equal "test-image.jpg", @service.blob.name
            assert_equal "image/jpeg", @service.blob.mime_type
            assert_equal 5, @service.blob.derivatives_count
          end
        end
      end
    end

    test "retrieve_data raises error when media record not found" do
      @service.stub :get_media_record, empty_media_response do
        error = assert_raises(RuntimeError) { @service.retrieve_data }
        assert_match(/Record not found/, error.message)
      end
    end

    test "retrieve_data raises error when duplicate media records found" do
      @service.stub :get_media_record, duplicate_media_response do
        error = assert_raises(RuntimeError) { @service.retrieve_data }
        assert_match(/Duplicate ID found/, error.message)
      end
    end

    test "retrieve_data raises error when media request fails" do
      @service.stub :get_media_record, failed_response do
        error = assert_raises(RuntimeError) { @service.retrieve_data }
        assert_match(/Error retrieving media record/, error.message)
      end
    end

    test "retrieve_data skips blob and derivatives when no blob csid" do
      @service.stub :get_media_record, media_response_without_blob do
        @service.retrieve_data

        assert_nil @service.blob.csid
        assert_nil @service.blob.mime_type
      end
    end

    test "retrieve_data skips derivatives when blob is not derivable" do
      @service.stub :get_media_record, media_response do
        @service.stub :get_blob_record, blob_response_pdf do
          @service.retrieve_data

          assert_equal "application/pdf", @service.blob.mime_type
          assert_nil @service.blob.derivatives_count
        end
      end
    end

    private

    def media_response
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "abstract_common_list" => {
            "itemsInPage" => 1,
            "list_item" => {
              "csid" => "media-csid-456",
              "blobCsid" => "blob-csid-123"
            }
          }
        }
      )
    end

    def media_response_without_blob
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "abstract_common_list" => {
            "itemsInPage" => 1,
            "list_item" => {
              "csid" => "media-csid-456",
              "blobCsid" => nil
            }
          }
        }
      )
    end

    def empty_media_response
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "abstract_common_list" => {
            "itemsInPage" => 0
          }
        }
      )
    end

    def duplicate_media_response
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "abstract_common_list" => {
            "itemsInPage" => 2
          }
        }
      )
    end

    def failed_response
      OpenStruct.new(
        result: OpenStruct.new(success?: false)
      )
    end

    def blob_response
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "document" => {
            "blobs_common" => {
              "length" => "1234567",
              "digest" => "abc123def",
              "name" => "test-image.jpg",
              "mimeType" => "image/jpeg"
            }
          }
        }
      )
    end

    def blob_response_pdf
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "document" => {
            "blobs_common" => {
              "length" => "999999",
              "digest" => "xyz789",
              "name" => "test-doc.pdf",
              "mimeType" => "application/pdf"
            }
          }
        }
      )
    end

    def derivatives_response
      OpenStruct.new(
        result: OpenStruct.new(success?: true),
        parsed: {
          "abstract_common_list" => {
            "itemsInPage" => 5
          }
        }
      )
    end
  end
end
