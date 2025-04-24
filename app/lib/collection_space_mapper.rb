# frozen_string_literal: true

module CollectionSpaceMapper
  class << self
    def single_record_type_handler_for(activity)
      CollectionSpace::Mapper::SingleRecordType::Handler.new(
        record_mapper: activity.data_config.url,
        client: activity.user.client,
        cache: Rails.cache,
        config: {}
      )
    end
  end
end
