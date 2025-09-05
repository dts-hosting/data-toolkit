require "test_helper"
# TODO: Activity subclass tests

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type

    @activity = Activity.new(
      user: @user,
      data_config: @data_config,
      type: "Activities::ExportRecordIds",
      label: "Test Activity Label"
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

  # Label validation tests
  test "should require a label" do
    @activity.label = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:label]
  end

  test "should require label to be at least 3 characters" do
    @activity.label = "ab"
    refute @activity.valid?
    assert_not_nil @activity.errors[:label]
  end

  test "should accept label with exactly 3 characters" do
    @activity.label = "abc"
    assert @activity.valid?
  end

  test "should accept label with more than 3 characters" do
    @activity.label = "Valid Activity Label"
    assert @activity.valid?
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
    # TODO: update when workflow fully defined

    assert_equal current_expected, activity.current_task
    assert_nil activity.next_task
    activity.destroy
  end

  # Auto-advance tests
  test "should have auto_advanced field defaulting to true" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    assert activity.auto_advanced?
  end

  # TODO: something for real if we're not just logging
  test "handle_advance should log when auto_advanced changes from true to false" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: true},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    # Capture log output
    log_output = StringIO.new
    logger = Logger.new(log_output)
    Rails.stub :logger, logger do
      activity.update!(auto_advanced: false)
    end

    assert_includes log_output.string, "Auto-advance disabled"
  end

  # TODO: something for real if we're not just logging
  test "handle_advance should log when final task completes successfully" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: true},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    final_task = activity.tasks.last
    # skip to the end
    final_task.update!(status: "succeeded", completed_at: Time.current)

    # Capture log output
    log_output = StringIO.new
    logger = Logger.new(log_output)
    Rails.stub :logger, logger do
      activity.touch
    end

    assert_includes log_output.string, "Workflow completed successfully"
  end

  # TODO: something for real if we're not just logging
  test "handle_advance should not run when auto_advance is disabled" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: false},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    # Capture log output
    log_output = StringIO.new
    logger = Logger.new(log_output)
    Rails.stub :logger, logger do
      activity.update!(auto_advanced: true)
    end

    # Should not contain any auto-advance related logs
    assert_not_includes log_output.string, "Auto-advance"
    assert_not_includes log_output.string, "Final task"
  end

  # TODO: something for real if we're not just logging
  test "handle_advance should not log when auto_advanced changes from false to true" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: true},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    # Capture log output
    log_output = StringIO.new
    logger = Logger.new(log_output)
    Rails.stub :logger, logger do
      activity.update!(auto_advanced: true)
    end

    # Should not log when changing from false to true
    assert_not_includes log_output.string, "Auto-advance disabled"
  end
end
