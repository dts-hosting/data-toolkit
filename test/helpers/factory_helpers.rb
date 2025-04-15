module FactoryHelpers
  # @param filenames [Array<String>] names of files in test/fixtures/files
  # @return [Array<Rack::Test::UploadedFile>] that can be attached to Activities
  def create_uploaded_files(filenames)
    filenames.map do |filename|
      path = fixture_file_path(filename)
      ext = path.extname.delete_prefix(".")
      mimetype = Mime::Type.lookup_by_extension(ext).to_s
      Rack::Test::UploadedFile.new(path, mimetype)
    end
  end

  def create_activity(attributes = {})
    attributes = {
      user: users(:admin),
      type: "Activities::ExportRecordIds"
    }.merge(attributes)
    attributes[:data_config] = create_data_config_record_type unless attributes[:data_config]
    Activity.create(attributes)
  end

  def create_data_config_record_type(attributes = {})
    attributes = {
      config_type: "record_type",
      profile: "core",
      version: "1.0.0",
      record_type: "collectionobject",
      url: "https://example.com/collectionobject-1.0.0.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_config_term_lists(attributes = {})
    attributes = {
      config_type: "term_lists",
      profile: "core",
      version: "1.0.0",
      url: "https://example.com/vocabularies-1.0.0.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_config_optlist_overrides(attributes = {})
    attributes = {
      config_type: "optlist_overrides",
      profile: "core",
      url: "https://example.com/optlist.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_items_for_task(task, n = 5)
    n.times do |i|
      task.activity.data_items.create!(
        current_task_id: task.id,
        position: i,
        data: {content: "Data #{i + 1}"}
      )
    end
  end
end
