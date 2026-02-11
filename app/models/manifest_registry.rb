class ManifestRegistry < ApplicationRecord
  include RequiresUrl

  has_many :manifests, dependent: :destroy

  validates :url, uniqueness: true

  broadcasts_refreshes

  # Import manifests from a registry
  # @return [void]
  def import(&block)
    response = Net::HTTP.get_response(URI.parse(url))
    raise "Failed to fetch manifest registry" unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    return unless should_process?(data["last_updated_at"])

    # TODO: collect manifest_urls and use to determine if an existing manifest
    # needs to be removed (because no longer present in the registry)
    data["manifests"].each do |manifest_url|
      manifest = Manifest.find_or_create_by(manifest_registry: self, url: manifest_url)
      unless manifest.valid?
        Rails.logger.debug { "Manifest could not be imported: #{manifest.errors.full_messages.join(";")}" }
        next
      end

      yield manifest if block_given?
    end

    update(last_updated_at: data["last_updated_at"])
  end

  def safe_to_delete?
    !manifests.joins(data_configs: :activities).exists?
  end

  private

  def should_process?(registry_updated_at)
    return true if last_updated_at.nil?

    parsed_registry_updated_at = parse_updated_at(registry_updated_at)
    return true unless parsed_registry_updated_at

    parsed_registry_updated_at > last_updated_at
  end

  def parse_updated_at(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
