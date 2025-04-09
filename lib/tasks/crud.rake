namespace :crud do
  namespace :create do
    def convert_empty_strings_to_nil(hash)
      hash.transform_values! { |v| (v.is_a?(String) && v.empty?) ? nil : v }
    end

    def create_or_update_data_config(opts)
      convert_empty_strings_to_nil(opts)
      existing = find_existing_data_config(opts)
      if existing.empty?
        data_config = DataConfig.new(opts)
        save_and_print(data_config)
      else
        data_config = existing.first
        data_config.update(url: opts[:url])
        puts "UPDATED URL:\n#{data_config.to_json}"
      end
    end

    def find_existing_data_config(opts)
      DataConfig.where(config_type: opts[:config_type],
        profile: opts[:profile],
        version: opts[:version],
        record_type: opts[:record_type])
    end

    def save_and_print(object)
      unless object.valid?
        puts object.errors.full_messages.to_json
      end

      object.save
      puts object.to_json
    end

    desc "Create a new Activity"
    task :activity, [:user_id, :data_config_id, :type, :file] => :environment do |_t, args|
      file = args.fetch(:file, nil)
      file = Rack::Test::UploadedFile.new(file, "text/csv") if file && File.exist?(file)

      opts = {
        user_id: args.fetch(:user_id),
        data_config_id: args.fetch(:data_config_id),
        type: args.fetch(:type),
        files: [file].compact
      }

      convert_empty_strings_to_nil(opts)
      activity = Activity.new(opts)
      save_and_print(activity)
    end

    desc "Create a new DataConfig"
    task :data_config, [:config_type, :profile, :version, :record_type, :url] => :environment do |_t, args|
      opts = {
        config_type: args.fetch(:config_type),
        profile: args.fetch(:profile),
        version: args.fetch(:version),
        record_type: args.fetch(:record_type),
        url: args.fetch(:url)
      }

      create_or_update_data_config(opts)
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

  namespace :import do
    desc "Import DataConfigs from a manifest"
    task :data_config_manifest, [:url] => :environment do |t, args|
      url = args[:url]
      raise "Invalid URL: #{url}" unless url.present? &&
        url =~ URI::DEFAULT_PARSER.make_regexp

      response = Net::HTTP.get_response(URI.parse(url))
      unless response.is_a?(Net::HTTPSuccess)
        raise "Manifest download failed: [#{response.code}] #{response.body}"
      end

      data = JSON.parse(response.body)
      unless data[data.keys.first]&.is_a?(Array)
        raise "Invalid manifest, expected array: #{response.body}"
      end

      data[data.keys.first].each do |entry|
        opts = {
          config_type: entry["dataConfigType"].tr(" ", "_").to_sym,
          profile: entry["profile"],
          version: entry["version"],
          record_type: entry["type"],
          url: entry["url"]
        }
        create_or_update_data_config(opts)
      end
    end
  end
end
