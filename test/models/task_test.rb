require "test_helper"
require "minitest/mock"

class TaskTest < ActiveSupport::TestCase
  def setup
    @task = Task.new(
      type: "Tasks::ProcessUploadedFiles",
      activity: create_activity
    )
  end

  test "should be valid with required attributes" do
    assert @task.valid?
  end

  test "should require type" do
    @task.type = nil
    assert_not @task.valid?
    assert_includes @task.errors[:type], "can't be blank"
  end

  test "should require activity" do
    @task.activity = nil
    assert_not @task.valid?
    assert_includes @task.errors[:activity], "must exist"
  end

  test "should require progress_status" do
    @task.progress_status = nil
    assert_not @task.valid?
    assert_includes @task.errors[:progress_status], "can't be blank"
  end

  test "should have default progress_status of pending" do
    task = Task.new
    assert_equal "pending", task.progress_status
  end

  test "should allow valid progress_status values" do
    %w[pending queued running completed].each do |status|
      @task.progress_status = status
      assert @task.valid?, "#{status} should be a valid progress_status"
    end
  end

  test "should allow valid outcome_status values" do
    %w[review failed succeeded].each do |status|
      @task.outcome_status = status
      assert @task.valid?, "#{status} should be a valid outcome_status"
    end
  end

  test "should track timestamps for task progression" do
    @task.save!

    @task.start!
    assert_not_nil @task.started_at
    assert_equal "running", @task.progress_status

    @task.done!("succeeded")
    assert_equal "succeeded", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "should attach files" do
    @task.save!

    file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    @task.files.attach(file)
    assert @task.files.attached?
    assert_equal 1, @task.files.count
  end

  # dependencies
  test "should handle dependencies correctly" do
    activity = create_activity(
      {
        type: "Activities::CreateOrUpdateRecords",
        config: {action: "create"},
        data_config: create_data_config_record_type({record_type: "acquisitions"}),
        files: create_uploaded_files(["test.csv"])
      }
    )
    first_task = activity.tasks[0]
    dependent_task = activity.tasks[1]

    assert_includes dependent_task.dependencies, first_task.class
    assert_not dependent_task.ok_to_run?

    first_task.done!("succeeded")
    assert dependent_task.ok_to_run?
  end

  # status transitions
  test "should execute start! method correctly" do
    @task.save!
    @task.start!

    assert_equal "running", @task.progress_status
    assert_not_nil @task.started_at
  end

  test "should execute done! method correctly with outcome" do
    @task.save!
    @task.done!("succeeded")

    assert_equal "succeeded", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "should execute done! method correctly with feedback" do
    feedback_hash = {"parent" => "Tasks::ProcessUploadedFiles",
                     "errors" =>
     [{"type" => "error",
       "subtype" => "csvlint_invalid_encoding",
       "details" => "row 2",
       "prefix" => "invalid_encoding.csv"}],
                     "warnings" => [],
                     "messages" => []}

    @task.save!
    @task.done!("failed", feedback_hash)

    assert_equal "failed", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
    feedback = @task.feedback_for
    refute feedback.ok?
  end

  # progress checking
  test "progress should be 0 when progress_status is pending" do
    @task.progress_status = "pending"
    assert_equal 0, @task.progress
  end

  test "progress should be 0 when progress_status is queued" do
    @task.progress_status = "queued"
    assert_equal 0, @task.progress
  end

  test "progress should be 100 when progress_status is completed" do
    @task.progress_status = "completed"
    assert_equal 100, @task.progress
  end

  test "progress should calculate percentage when progress_status is running" do
    @task.save!
    create_actions_for_task(@task)
    @task.progress_status = "running"

    @task.actions.first.update(progress_status: "completed")
    @task.actions.last.update(progress_status: "completed")

    # Should be 40% complete (2 out of 5 actions)
    assert_equal 40, @task.progress
  end

  test "progress should be 0 when running with no actions" do
    @task.progress_status = "running"
    assert_equal 0, @task.progress
  end

  test "progress should trigger finalize_status when reaching 100%" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: "running")

    @task.actions.update_all(progress_status: "completed")
    @task.actions.last.update(progress_status: "completed")
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "succeeded", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to failed if all actions have errors" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: "running")

    @task.actions.update_all(
      progress_status: "completed",
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )
    @task.actions.last.update(
      progress_status: "completed",
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "failed", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to review if any (not all) actions have errors" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: "running")

    @task.actions.limit(4).update_all(progress_status: "completed")
    @task.actions.last.update(
      progress_status: "completed",
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "review", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to review if any actions have warnings" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: "running")

    @task.actions.limit(4).update_all(progress_status: "completed")
    @task.actions.last.update(
      progress_status: "completed",
      feedback: {"warnings" => [{"type" => "warning", "details" => "test"}]}
    )
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "review", @task.outcome_status
    assert_equal "completed", @task.progress_status
    assert_not_nil @task.completed_at
  end

  # Tests for the separation of status setting and finalizer execution
  test "handle_completion should run finalizer when first transitioning to completed (not successful) status" do
    @task.save!
    mock_finalizer = Minitest::Mock.new
    mock_finalizer.expect :perform_later, nil, [@task]

    @task.stub :finalizer, mock_finalizer do
      @task.update!(progress_status: "completed", outcome_status: "review", completed_at: Time.current)
    end

    mock_finalizer.verify
    assert_equal "review", @task.outcome_status
    assert_equal "completed", @task.progress_status
  end

  test "handle_completion should not run finalizer when transitioning outcome status only" do
    @task.save!
    # First get task into a completed status
    @task.update!(progress_status: "completed", outcome_status: "review", completed_at: Time.current)

    # Now mock the finalizer and transition to another outcome status
    mock_finalizer = Minitest::Mock.new
    # No expectation set - the finalizer should not be called for this transition

    @task.stub :finalizer, mock_finalizer do
      @task.update!(outcome_status: "succeeded")
    end

    mock_finalizer.verify
    assert_equal "succeeded", @task.outcome_status
  end

  test "handle_completion should not run finalizer when progress_status change is not to completed" do
    mock_finalizer = Minitest::Mock.new
    # No expectation set - the finalizer should not be called

    @task.stub :finalizer, mock_finalizer do
      @task.save!
      @task.update!(progress_status: "running", started_at: Time.current)
    end

    mock_finalizer.verify
    assert_equal "running", @task.progress_status
  end

  # has_feedback? method tests
  test "has_feedback? should return false when task progress is not completed" do
    @task.save!
    @task.progress_status = "pending"
    assert_not @task.has_feedback?

    @task.progress_status = "running"
    assert_not @task.has_feedback?
  end

  test "has_feedback? should return false when task progress is completed but no feedback" do
    @task.save!
    @task.update!(progress_status: "completed", outcome_status: "succeeded")
    assert_not @task.has_feedback?
  end

  test "has_feedback? should return true when task is completed and feedback_for is displayable" do
    feedback_hash = {"parent" => "Tasks::ProcessUploadedFiles",
                     "errors" => [],
                     "warnings" =>
     [{"type" => "warning",
       "subtype" => "csvlint_check_options",
       "details" => "check not good",
       "prefix" => "test.csv"}],
                     "messages" => []}

    @task.save!
    @task.done!("review", feedback_hash)

    assert @task.progress_completed?
    assert @task.feedback_for.displayable?
    assert @task.has_feedback?
  end

  test "has_feedback? should return true when task is completed and actions have feedback" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: "completed", outcome_status: "succeeded")

    # add feedback to an action
    @task.actions.first.update!(feedback: {"errors" => [{"type" => "error", "details" => "test error"}]})

    assert @task.progress_completed?
    assert @task.has_feedback?
  end

  # Auto-advance functionality tests
  test "handle_completion should trigger auto-advance when task succeeds and auto_advance is enabled" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: true},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.first
    second_task = activity.tasks.second

    # Set up the correct initial state
    first_task.update!(progress_status: "running", started_at: Time.current)
    second_task.update!(progress_status: "pending")

    # Verify initial state
    assert_equal true, activity.config["auto_advance"]
    assert_equal 2, activity.tasks.count
    assert_equal second_task, activity.next_task
    assert_equal "pending", second_task.progress_status

    # Trigger auto-advance by completing the first task
    first_task.update!(progress_status: "completed", outcome_status: "succeeded", completed_at: Time.current)

    # Verify auto-advance occurred
    activity.reload
    second_task.reload

    assert activity.auto_advanced?, "Activity should have auto_advanced set to true"
    assert_equal "queued", second_task.progress_status, "Next task should have been queued (run was called)"
  end

  test "handle_completion should not trigger auto-advance when task succeeds but auto_advance is disabled" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.first
    first_task.update!(progress_status: "completed", outcome_status: "succeeded", completed_at: Time.current)

    activity.reload
    assert_not activity.auto_advanced?
  end

  test "handle_completion should set auto_advanced to false when running finalizer for failed task" do
    activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: true},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.first
    mock_finalizer = Minitest::Mock.new
    mock_finalizer.expect :perform_later, nil, [first_task]

    first_task.stub :finalizer, mock_finalizer do
      first_task.update!(progress_status: "completed", outcome_status: "failed", completed_at: Time.current)
    end

    activity.reload
    assert_not activity.auto_advanced?
    mock_finalizer.verify
  end

  # create_actions_for_data_items tests
  test "create_actions_for_data_items should create actions for all data items when none have errors" do
    @task.save!
    5.times do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    @task.create_actions_for_data_items

    assert_equal 5, @task.actions.count
    assert_equal 5, @task.data_items.count
  end

  test "create_actions_for_data_items should exclude data items with errors from previous actions" do
    @task.save!
    data_items = 5.times.map do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    # Create a previous action with errors for one data item
    previous_task = @task.activity.tasks.create!(type: "Tasks::PreCheckIngestData")
    Action.create!(
      task: previous_task,
      data_item: data_items[0],
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )

    @task.create_actions_for_data_items

    assert_equal 4, @task.actions.count
    assert_equal 4, @task.data_items.count
    assert_not_includes @task.data_items, data_items[0]
  end
end
