require "test_helper"

class DataItemTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    activity = create_activity
    @data_item = DataItem.new(
      data: {objectNumber: "123"},
      position: 0,
      activity: activity
    )
  end

  test "valid data item" do
    assert @data_item.valid?
  end

  test "requires data" do
    @data_item.data = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:data], "can't be blank"
  end

  test "requires position" do
    @data_item.position = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:position], "can't be blank"
  end

  test "requires activity" do
    @data_item.activity = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:activity], "must exist"
  end

  test "position must be unique within activity scope" do
    duplicate_item = @data_item.dup
    @data_item.save!
    refute duplicate_item.valid?
    assert_includes duplicate_item.errors[:position], "has already been taken"
  end

  test "should have many actions" do
    @data_item.save!
    task1 = @data_item.activity.tasks.find_or_create_by!(type: :pre_check_ingest_data)
    task2 = @data_item.activity.tasks.find_or_create_by!(type: :process_uploaded_files)

    action1 = Action.find_or_create_by!(task: task1, data_item: @data_item)
    action2 = Action.find_or_create_by!(task: task2, data_item: @data_item)

    assert_equal 2, @data_item.actions.count
    assert_includes @data_item.actions, action1
    assert_includes @data_item.actions, action2
  end

  test "should have many tasks through actions" do
    @data_item.save!
    task1 = @data_item.activity.tasks.find_or_create_by!(type: :pre_check_ingest_data)
    task2 = @data_item.activity.tasks.find_or_create_by!(type: :process_uploaded_files)

    Action.find_or_create_by!(task: task1, data_item: @data_item)
    Action.find_or_create_by!(task: task2, data_item: @data_item)

    assert_equal 2, @data_item.tasks.count
    assert_includes @data_item.tasks, task1
    assert_includes @data_item.tasks, task2
  end

  test "should attach an xml payload" do
    @data_item.save!
    refute @data_item.payload.attached?

    xml = "<document><objectNumber>123</objectNumber></document>"
    @data_item.payload.attach(
      io: StringIO.new(xml),
      filename: "#{@data_item.id}.xml",
      content_type: "application/xml"
    )

    assert @data_item.payload.attached?
    assert_equal xml, @data_item.reload.payload.download
    assert_equal "application/xml", @data_item.payload.content_type
  end

  test "should replace an existing payload" do
    @data_item.save!
    @data_item.payload.attach(io: StringIO.new("<old/>"), filename: "old.xml", content_type: "application/xml")
    @data_item.payload.attach(io: StringIO.new("<new/>"), filename: "new.xml", content_type: "application/xml")

    assert_equal "<new/>", @data_item.reload.payload.download
    assert_equal 1, ActiveStorage::Attachment.where(record: @data_item, name: "payload").count
  end

  test "should purge payload when destroyed" do
    @data_item.save!
    @data_item.payload.attach(io: StringIO.new("<xml/>"), filename: "item.xml", content_type: "application/xml")
    blob = @data_item.payload.blob

    assert_enqueued_with(job: ActiveStorage::PurgeJob, args: [blob]) do
      @data_item.destroy!
    end

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob)
    refute ActiveStorage::Blob.exists?(blob.id)
  end
end
