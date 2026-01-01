module FactoryHelpers
  def create_action_with_feedback(task)
    data_item = task.activity.data_items.create!(
      position: next_item_position(task.activity.data_items),
      data: {"field" => "value"}
    )
    action = task.actions.create!(data_item: data_item)

    feedback = Feedback.new(task.class.name)
    feedback.add_to_errors(subtype: :test_error, details: "error")
    action.update!(feedback: feedback)
    action
  end

  def create_action_without_feedback(task)
    data_item = task.activity.data_items.create!(
      position: next_item_position(task.activity.data_items),
      data: {"field" => "value"}
    )
    task.actions.create!(data_item: data_item)
  end

  def create_actions_with_feedback(task)
    2.times do |i|
      data_item = task.activity.data_items.create!(
        position: next_item_position(task.activity.data_items),
        data: {"field1" => "value#{i}", "field2" => "data#{i}"}
      )
      action = task.actions.create!(data_item: data_item)

      feedback = Feedback.new(task.class.name)
      feedback.add_to_errors(subtype: :test_error, details: "error #{i}")
      feedback.add_to_warnings(subtype: :test_warning, details: "warning #{i}")
      action.update!(feedback: feedback)
    end

    task.actions.where.not(feedback: nil)
  end

  def create_actions_for_task(task, n = 5)
    create_data_items_for_task(task, n)
  end

  def create_activity(attributes = {})
    attributes = {
      user: users(:admin),
      type: :export_record_ids,
      label: "Test Label #{SecureRandom.hex(4)}"
    }.merge(attributes)
    attributes[:data_config] = create_data_config_record_type unless attributes[:data_config]
    activity = Activity.new(attributes)

    if activity.has_batch_config? && !activity.batch_config
      activity.build_batch_config
    end

    activity.save!
    activity
  end

  def create_data_config_record_type(attributes = {})
    attributes = {
      manifest: manifests(:v1),
      config_type: "record_type",
      profile: "core",
      version: "1.0.0",
      record_type: "collectionobject",
      url: "https://example.com/collectionobject-1.0.0.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_config_term_list(attributes = {})
    attributes = {
      manifest: manifests(:v1),
      config_type: "term_list",
      profile: "core",
      version: "1.0.0",
      url: "https://example.com/vocabularies-1.0.0.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_config_optlist_override(attributes = {})
    attributes = {
      manifest: manifests(:v1),
      config_type: "optlist_override",
      profile: "core",
      url: "https://example.com/optlist.json"
    }.merge(attributes)
    DataConfig.create(attributes)
  end

  def create_data_items_for_task(task, n = 5)
    n.times do |i|
      data_item = task.activity.data_items.create!(
        position: i,
        data: {content: "Data #{i + 1}"}
      )
      task.actions.create!(data_item: data_item)
    end
  end

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

  def valid_user_attributes
    {
      email_address: "user@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org/cspace-services",
      cspace_api_version: "1.0",
      cspace_profile: "core",
      cspace_ui_version: "1.0"
    }
  end

  private

  def next_item_position(data_items)
    (data_items.any? ? data_items.maximum(:position) : 0) + 1
  end
end
