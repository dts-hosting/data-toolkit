class ManifestRegistryImportJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :manifest_registry_import_job, duration: 30.minutes

  def perform
    ManifestRegistry.find_each do |registry|
      registry.import do |manifest|
        Rails.logger.info "Importing data configs from: #{manifest.url}"
        manifest.import
      end
    end
  end
end
