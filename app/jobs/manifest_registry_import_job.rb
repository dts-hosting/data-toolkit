class ManifestRegistryImportJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :manifest_registry_import_job, duration: 30.minutes

  def perform(manifest_registry = nil)
    if manifest_registry
      import_registry(manifest_registry)
    else
      ManifestRegistry.find_each do |registry|
        import_registry(registry)
      end
    end
  end

  private

  def import_registry(registry)
    registry.import do |manifest|
      Rails.logger.info "Importing data configs from: #{manifest.url}"
      manifest.import
    end
  end
end
