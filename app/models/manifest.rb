class Manifest < ApplicationRecord
  include RequiresUrl
  belongs_to :manifest_registry
  has_many :data_configs, dependent: :destroy

  # Import data configs from a manifest
  # @return [void]
  def import
    response = Net::HTTP.get_response(URI.parse(url))
    raise "Failed to fetch manifest" unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    unless data[data.keys.first]&.is_a?(Array)
      raise "Invalid manifest, expected array: #{response.body}"
    end

    data[data.keys.first].each do |entry|
      url = entry["url"]
      opts = {
        manifest: self,
        config_type: entry["dataConfigType"].tr(" ", "_").to_sym,
        profile: entry["profile"],
        version: entry["version"],
        record_type: entry["type"]
      }
      data_config = DataConfig.find_or_create_by(opts)
      data_config.update(url: url) if url != data_config.url
    end
  end
end
