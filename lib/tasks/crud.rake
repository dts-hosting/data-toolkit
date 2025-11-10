namespace :crud do
  namespace :create do
    def convert_empty_strings_to_nil(hash)
      hash.transform_values! { |v| (v.is_a?(String) && v.empty?) ? nil : v }
    end

    def save_and_print(object)
      unless object.valid?
        puts object.errors.full_messages.to_json
      end

      object.save
      puts object.to_json
    end

    desc "Create a new Activity"
    task :activity, [:user_id, :label, :type, :data_config_id, :file] => :environment do |_t, args|
      file = args.fetch(:file, nil)
      file = Rack::Test::UploadedFile.new(file, "text/csv") if file && File.exist?(file)

      opts = {
        user_id: args.fetch(:user_id),
        data_config_id: args.fetch(:data_config_id),
        type: args.fetch(:type),
        label: args.fetch(:label),
        files: [file].compact
      }

      convert_empty_strings_to_nil(opts)
      activity = Activity.new(opts)
      activity.build_batch_config
      save_and_print(activity)
    end

    task :user, [:cspace_url, :email_address, :password] => :environment do |_t, args|
      opts = {
        cspace_url: args.fetch(:cspace_url),
        email_address: args.fetch(:email_address),
        password: args.fetch(:password)
      }
      client = CollectionSpaceApi.client_for(
        opts[:cspace_url], opts[:email_address], opts[:password]
      )
      version_data = client.version
      user = User.new(
        opts.merge(
          cspace_url: client.config.base_uri,
          cspace_api_version: version_data.api.joined,
          cspace_profile: version_data.ui.profile,
          cspace_ui_version: version_data.ui.version
        )
      )
      save_and_print(user)
    end
  end

  namespace :read do
    desc "Find data configs by user"
    task :data_configs, [:user_id, :data_config_type, :record_type] => :environment do |_t, args|
      user = User.find(args.fetch(:user_id))
      data_config_type = args.fetch(:data_config_type)
      record_type = args.fetch(:record_type, nil)

      data_configs = DataConfig.send(data_config_type.to_sym, user)
      data_configs = data_configs.where(record_type: record_type) if record_type
      puts data_configs.to_json
    end

    desc "List tasks for activity"
    task :tasks, [:activity_id] => :environment do |_t, args|
      activity = Activity.find(args.fetch(:activity_id))
      puts activity.tasks.to_json
    end
  end

  namespace :import do
    desc "Import DataConfigs from a ManifestRegistry"
    task :manifest_registry, [:url] => :environment do |t, args|
      registry = ManifestRegistry.find_or_create_by(url: args.fetch(:url))
      registry.update(last_updated_at: nil)
      ManifestRegistryImportJob.perform_now
      puts ManifestRegistry.last.manifests.to_json
    end
  end
end
