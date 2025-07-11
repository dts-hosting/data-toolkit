require "test_helper"
# TODO: Activity subclass tests

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type

    @activity = Activity.new(
      user: @user,
      data_config: @data_config,
      type: "Activities::ExportRecordIds"
    )
  end

  test "should be valid with required attributes" do
    assert @activity.valid?
  end

  test "should require a user" do
    @activity.user = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:user]
  end

  test "should require a data_config" do
    @activity.data_config = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:data_config]
  end

  test "should require a type" do
    @activity.type = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:type]
  end

  test "should allow file attachments" do
    @activity.files.attach(
      io: StringIO.new("test content"),
      filename: "test.csv",
      content_type: "text/csv"
    )
    assert @activity.files.attached?
  end

  test "current_task returns the first task when new activity created" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    current_expected = activity.tasks.where(type: "Tasks::ProcessUploadedFiles").first
    next_expected = activity.tasks.where(type: "Tasks::PreCheckIngestData").first

    assert_equal current_expected, activity.current_task
    assert_equal next_expected, activity.next_task
    activity.destroy
  end

  test "current_task returns first non-pending, most recently created task" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    current_expected = activity.tasks.where(type: "Tasks::PreCheckIngestData").first
    current_expected.queued!
    next_expected = nil # TODO: update when workflow fully defined

    assert_equal current_expected, activity.current_task
    assert_equal next_expected, activity.next_task
    activity.destroy
  end
end
