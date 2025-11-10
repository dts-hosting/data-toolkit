module CollectionSpace
  class CheckMediaService
    attr_reader :client, :opts, :name, :blob

    Blob = Struct.new(
      :csid,
      :media_csid,
      :length,
      :digest,
      :name,
      :mime_type,
      :derivatives_count
    )
    DERIVABLE_IMAGE_TYPES = %w[
      image/jpeg image/bmp image/gif image/png image/tiff
    ]
    EXPECTED_DERIVABLE_COUNT = 5
    VALID_TYPES = %w[media restricted_media].freeze

    def initialize(client, opts)
      @client = client
      @opts = opts
      @name = "#{opts[:type]} #{opts[:field]} #{opts[:value]}"
      @blob = Blob.new
    end

    def is_derivable?
      blob.csid && DERIVABLE_IMAGE_TYPES.include?(blob.mime_type)
    end

    def has_derivatives?
      blob.csid && blob.derivatives_count.to_i > 0
    end

    def has_all_derivatives?
      blob.csid && blob.derivatives_count.to_i == EXPECTED_DERIVABLE_COUNT
    end

    def retrieve_data
      retrieve_media_data
      retrieve_blob_data
      retrieve_derivatives_data
    end

    def valid?
      VALID_TYPES.include?(opts[:type])
    end

    def verify?
      has_all_derivatives?
    end

    private

    def get_blob_record
      client.get("blobs/#{blob.csid}")
    end

    def get_derivatives_record
      client.get("blobs/#{blob.csid}/derivatives")
    end

    def get_media_record
      client.find(
        type: opts[:type],
        field: opts[:field],
        value: opts[:value].to_s
      )
    end

    def parse_blob_record(response)
      blob_data = response.parsed["document"]["blobs_common"]
      blob.length = blob_data["length"]
      blob.digest = blob_data["digest"]
      blob.name = blob_data["name"]
      blob.mime_type = blob_data["mimeType"]
    end

    def parse_derivatives_record(response)
      i = response.parsed["abstract_common_list"].fetch("itemsInPage", 0).to_i
      blob.derivatives_count = i
    end

    def parse_media_record(response)
      items_in_page = response.parsed["abstract_common_list"].fetch("itemsInPage", 0).to_i
      if items_in_page.zero?
        raise "Record not found"
      elsif items_in_page > 1
        raise "Duplicate ID found"
      end

      blob.csid = response.parsed["abstract_common_list"]["list_item"]["blobCsid"]
      blob.media_csid = response.parsed["abstract_common_list"]["list_item"]["csid"]
    end

    def retrieve_blob_data
      return unless blob.csid

      response = get_blob_record
      unless response.result.success?
        raise "Error retrieving blob: #{response.result}"
      end
      parse_blob_record(response)
    end

    def retrieve_derivatives_data
      return unless is_derivable?

      response = get_derivatives_record
      unless response.result.success?
        raise "Error retrieving derivatives: #{response.result}"
      end
      parse_derivatives_record(response)
    end

    def retrieve_media_data
      response = get_media_record
      unless response.result.success?
        raise "Error retrieving media record: #{response.result}"
      end
      parse_media_record(response)
    end
  end
end
