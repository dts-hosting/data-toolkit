require "test_helper"
# TODO: Activity subclass tests

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type

    @activity = Activity.new(
      user: @user,
      data_config: @data_config,
      type: :export_record_ids,
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
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    current_expected = activity.tasks.where(type: "process_uploaded_files").first
    next_expected = activity.tasks.where(type: "pre_check_ingest_data").first

    assert_equal current_expected, activity.current_task
    assert_equal next_expected, activity.next_task
    activity.destroy
  end

  test "current_task returns first non-pending, most recently created task" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    current_expected = activity.tasks.where(type: "pre_check_ingest_data").first
    current_expected.update!(progress_status: Task::QUEUED)
    # TODO: update when workflow fully defined

    assert_equal current_expected, activity.current_task
    assert_nil activity.next_task
    activity.destroy
  end

  # Auto-advance tests
  test "should have auto_advance field defaulting to true" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    assert activity.auto_advance?
  end

  test "activity type registry is immutable and includes configured types" do
    assert Activity.activity_types_registry.frozen?
    assert_includes Activity.activity_types_registry.keys, :create_or_update_records
  end

  test "creating activity with multi-step workflow produces expected task rows in order" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    task_types = activity.tasks.order(:created_at).pluck(:type)
    assert_equal ["process_uploaded_files", "pre_check_ingest_data"], task_types
    activity.destroy
  end

  test "creating activity with empty workflow produces zero task rows" do
    activity = create_activity(
      type: :export_record_ids,
      data_config: @data_config
    )

    assert_equal 0, activity.tasks.count
    activity.destroy
  end

  test "auto-trigger task transitions to queued after activity creation" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    auto_trigger_task = activity.tasks.find_by(type: "process_uploaded_files")
    assert_equal Task::QUEUED, auto_trigger_task.progress_status
    activity.destroy
  end

  test "workflow task creation is atomic — invalid task type rolls back activity and all tasks" do
    assert_no_difference ["Activity.count", "Task.count"] do
      assert_raises(ActiveRecord::RecordInvalid) do
        activity = Activity.new(
          user: @user,
          data_config: @data_config,
          type: :create_or_update_records,
          config: {action: "create"},
          label: "Test Rollback",
          files: create_uploaded_files(["test.csv"])
        )
        # Inject an invalid task type into the workflow
        activity.define_singleton_method(:workflow) do
          [:process_uploaded_files, :nonexistent_task_type]
        end
        activity.save!
      end
    end
  end

  test "auto-trigger sees all sibling tasks during execution" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )

    auto_trigger_task = activity.tasks.find_by(type: "process_uploaded_files")
    sibling_task = activity.tasks.find_by(type: "pre_check_ingest_data")

    assert_equal Task::QUEUED, auto_trigger_task.progress_status
    assert_not_nil sibling_task, "Sibling task should exist when auto-trigger fires"
    activity.destroy
  end

  test "creating activity with empty workflow persists activity with zero tasks" do
    activity = create_activity(
      type: :export_record_ids,
      data_config: @data_config
    )

    assert activity.persisted?
    assert_equal 0, activity.tasks.count
    activity.destroy
  end
end
