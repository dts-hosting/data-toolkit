require "test_helper"

class HistoryTest < ActiveSupport::TestCase
  test "should require activity_user" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_user], "can't be blank"
  end

  test "should require activity_url" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_url], "can't be blank"
  end

  test "should require activity_type" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_type], "can't be blank"
  end

  test "should require activity_label" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_label], "can't be blank"
  end

  test "should require activity_data_config_type" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_data_config_type], "can't be blank"
  end

  test "should require activity_created_at" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:activity_created_at], "can't be blank"
  end

  test "should require task_type" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:task_type], "can't be blank"
  end

  test "should require task_status" do
    history = History.new
    assert_not history.valid?
    assert_includes history.errors[:task_status], "can't be blank"
  end

  test "should serialize task_feedback as JSON" do
    feedback_data = {"errors" => [], "warnings" => ["test warning"]}
    history = History.new(
      activity_user: "test@example.com",
      activity_url: "https://test.org/cspace-services",
      activity_type: "Test Activity",
      activity_label: "test.csv",
      activity_data_config_type: "record_type",
      activity_data_config_record_type: "collectionobject",
      activity_created_at: Time.current,
      task_type: "Test Task",
      task_status: "succeeded",
      task_feedback: feedback_data
    )

    assert history.valid?
    history.save!
    history.reload
    assert_equal feedback_data, history.task_feedback
  end

  test "should create valid history with all required fields" do
    history = History.new(
      activity_user: "test@example.com",
      activity_url: "https://test.org/cspace-services",
      activity_type: "Test Activity",
      activity_label: "test.csv",
      activity_data_config_type: "record_type",
      activity_data_config_record_type: "collectionobject",
      activity_created_at: Time.current,
      task_type: "Test Task",
      task_status: "succeeded",
      task_feedback: {},
      task_started_at: Time.current,
      task_completed_at: Time.current
    )

    assert history.valid?
    assert history.save
  end

  test "should create history record when activity is destroyed" do
    user = users(:admin)
    data_config = create_data_config_record_type

    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: data_config,
      label: "test.csv",
      files: create_uploaded_files(["test.csv"])
    )
    created_at = activity.created_at
    activity.destroy!

    history = History.last
    assert_equal user.email_address, history.activity_user
    assert_equal user.cspace_url, history.activity_url
    assert_equal "Create or Update Records", history.activity_type
    assert_equal "test.csv", history.activity_label
    assert_equal created_at, history.activity_created_at
    assert_not_nil history.task_type
    assert_not_nil history.task_status
  end
end
