require "minitest/mock"

class TaskTest < ActiveSupport::TestCase
  def setup
    @task = Task.new(
      type: :process_uploaded_files,
      activity: create_activity
    )
  end

  test "should be valid with required attributes" do
    assert @task.valid?
  end

  test "task type registry is immutable and includes configured types" do
    assert Task.task_types_registry.frozen?
    assert_includes Task.task_types_registry.keys, :process_uploaded_files
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
    assert_equal Task::PENDING, task.progress_status
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
    assert_equal Task::RUNNING, @task.progress_status

    @task.done!(Task::SUCCEEDED)
    assert_equal Task::SUCCEEDED, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
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
        type: :create_or_update_records,
        config: {action: "create"},
        data_config: create_data_config_record_type({record_type: "acquisitions"}),
        files: create_uploaded_files(["test.csv"])
      }
    )
    first_task = activity.tasks.find_by(type: "process_uploaded_files")
    dependent_task = activity.tasks.find_by(type: "pre_check_ingest_data")

    assert_includes dependent_task.dependencies, first_task.task_type
    assert_not dependent_task.ok_to_run?

    first_task.done!(Task::SUCCEEDED)
    assert dependent_task.ok_to_run?
  end

  # status transitions
  test "should execute start! method correctly" do
    @task.save!
    @task.start!

    assert_equal Task::RUNNING, @task.progress_status
    assert_not_nil @task.started_at
  end

  test "should execute done! method correctly with outcome" do
    @task.save!
    @task.done!(Task::SUCCEEDED)

    assert_equal Task::SUCCEEDED, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
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
    @task.done!(Task::FAILED, feedback_hash)

    assert_equal Task::FAILED, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
    assert_not_nil @task.completed_at
    feedback = @task.feedback_for
    refute feedback.ok?
  end

  # progress checking
  test "progress should be 0 when progress_status is pending" do
    @task.progress_status = Task::PENDING
    assert_equal 0, @task.progress
  end

  test "progress should be 0 when progress_status is queued" do
    @task.progress_status = Task::QUEUED
    assert_equal 0, @task.progress
  end

  test "progress should be 100 when progress_status is completed" do
    @task.progress_status = Task::COMPLETED
    assert_equal 100, @task.progress
  end

  test "progress should calculate percentage when progress_status is running" do
    @task.save!
    create_actions_for_task(@task, 5, actions_completed_count: 2)
    @task.progress_status = Task::RUNNING

    assert_equal 40, @task.progress
  end

  test "progress should be 0 when running with no actions" do
    @task.progress_status = Task::RUNNING
    assert_equal 0, @task.progress
  end

  test "progress should trigger finalize_status when reaching 100%" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING)

    # Complete 4 via update_all (bypasses callbacks), then the last via update to trigger finalize
    @task.actions.limit(4).update_all(progress_status: Task::COMPLETED)
    @task.update_column(:actions_completed_count, 4)
    @task.actions.last.update(progress_status: Task::COMPLETED)
    @task.reload

    assert_equal 100, @task.progress
    assert_equal Task::SUCCEEDED, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to failed if all actions have errors" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING)

    feedback = {"errors" => [{"type" => "error", "details" => "test"}]}
    @task.actions.limit(4).update_all(progress_status: Task::COMPLETED, feedback: feedback)
    @task.update_column(:actions_completed_count, 4)
    @task.actions.last.update(progress_status: Task::COMPLETED, feedback: feedback)
    @task.reload

    assert_equal 100, @task.progress
    assert_equal Task::FAILED, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to review if any (not all) actions have errors" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING)

    @task.actions.limit(4).update_all(progress_status: Task::COMPLETED)
    @task.update_column(:actions_completed_count, 4)
    @task.actions.last.update(
      progress_status: Task::COMPLETED,
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )
    @task.reload

    assert_equal 100, @task.progress
    assert_equal Task::REVIEW, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
    assert_not_nil @task.completed_at
  end

  test "progress should set outcome to review if any actions have warnings" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING)

    @task.actions.limit(4).update_all(progress_status: Task::COMPLETED)
    @task.update_column(:actions_completed_count, 4)
    @task.actions.last.update(
      progress_status: Task::COMPLETED,
      feedback: {"warnings" => [{"type" => "warning", "details" => "test"}]}
    )
    @task.reload

    assert_equal 100, @task.progress
    assert_equal Task::REVIEW, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
    assert_not_nil @task.completed_at
  end

  # Tests for the separation of status setting and finalizer execution
  test "handle_completion should run finalizer when first transitioning to completed (not successful) status" do
    @task.save!
    mock_finalizer = Minitest::Mock.new
    mock_finalizer.expect :perform_later, nil, [@task]

    @task.activity.stub :current_task, @task do
      @task.stub :finalizer, mock_finalizer do
        @task.update!(progress_status: Task::COMPLETED, outcome_status: Task::REVIEW, completed_at: Time.current)
      end
    end

    mock_finalizer.verify
    assert_equal Task::REVIEW, @task.outcome_status
    assert_equal Task::COMPLETED, @task.progress_status
  end

  test "handle_completion should not run finalizer when transitioning outcome status only" do
    @task.save!
    # First get task into a completed status
    @task.update!(progress_status: Task::COMPLETED, outcome_status: Task::REVIEW, completed_at: Time.current)

    # Now mock the finalizer and transition to another outcome status
    mock_finalizer = Minitest::Mock.new
    # No expectation set - the finalizer should not be called for this transition

    @task.stub :finalizer, mock_finalizer do
      @task.update!(outcome_status: Task::SUCCEEDED)
    end

    mock_finalizer.verify
    assert_equal Task::SUCCEEDED, @task.outcome_status
  end

  test "handle_completion should not run finalizer when progress_status change is not to completed" do
    mock_finalizer = Minitest::Mock.new
    # No expectation set - the finalizer should not be called

    @task.stub :finalizer, mock_finalizer do
      @task.save!
      @task.update!(progress_status: Task::RUNNING, started_at: Time.current)
    end

    mock_finalizer.verify
    assert_equal Task::RUNNING, @task.progress_status
  end

  # has_feedback? method tests
  test "has_feedback? should return false when task progress is not completed" do
    @task.save!
    @task.progress_status = Task::PENDING
    assert_not @task.has_feedback?

    @task.progress_status = Task::RUNNING
    assert_not @task.has_feedback?
  end

  test "has_feedback? should return false when task progress is completed but no feedback" do
    @task.save!
    @task.update!(progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED)
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
    @task.done!(Task::REVIEW, feedback_hash)

    assert @task.progress_completed?
    assert @task.feedback_for.displayable?
    assert @task.has_feedback?
  end

  test "has_feedback? should return true when task is completed and actions have feedback" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED)

    # add feedback to an action
    @task.actions.first.update!(feedback: {"errors" => [{"type" => "error", "details" => "test error"}]})

    assert @task.progress_completed?
    assert @task.has_feedback?
  end

  # Auto-advance functionality tests
  test "handle_completion should trigger auto-advance when task succeeds and auto_advance is enabled" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: true},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.first
    second_task = activity.tasks.second

    # Set up the correct initial state
    first_task.update!(progress_status: Task::RUNNING, started_at: Time.current)
    second_task.update!(progress_status: Task::PENDING)

    # Verify initial state
    assert_equal true, activity.config["auto_advance"]
    assert_equal 2, activity.tasks.count
    assert_equal second_task, activity.next_task
    assert_equal Task::PENDING, second_task.progress_status

    # Ensure the next task has processable items to queue
    activity.data_items.create!(position: 0, data: {objectnumber: "OBJ1"})

    # Trigger auto-advance by completing the first task
    first_task.update!(progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED, completed_at: Time.current)

    # Verify auto-advance occurred
    activity.reload
    second_task.reload

    assert activity.auto_advance?, "Activity should have auto_advance set to true"
    assert_equal Task::QUEUED, second_task.progress_status, "Next task should have been queued (run was called)"
  end

  test "handle_completion should not trigger auto-advance when task succeeds but auto_advance is disabled" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.first
    first_task.update!(progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED, completed_at: Time.current)

    activity.reload
    assert_not activity.auto_advance?
  end

  test "handle_completion should set auto_advance to false when running finalizer for failed task" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: true},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    # Reload to re-establish inverse association cleared by with_lock during auto-trigger
    first_task = activity.tasks.reload.first
    mock_finalizer = Minitest::Mock.new
    mock_finalizer.expect :perform_later, nil, [first_task]

    activity.stub :current_task, first_task do
      first_task.stub :finalizer, mock_finalizer do
        first_task.update!(progress_status: Task::COMPLETED, outcome_status: Task::FAILED, completed_at: Time.current)
      end
    end

    activity.reload
    assert_not activity.auto_advance?
    mock_finalizer.verify
  end

  # create_actions_for_data_items tests
  test "create_actions_for_data_items should create actions for all data items when none have errors" do
    @task.save!
    5.times do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    @task.send(:create_actions_for_data_items)

    assert_equal 5, @task.actions.count
    assert_equal 5, @task.data_items.count
  end

  test "create_actions_for_data_items should exclude data items with errors from previous actions" do
    @task.save!
    data_items = 5.times.map do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    # Create a previous action with errors for one data item
    previous_task = @task.activity.tasks.create!(type: :pre_check_ingest_data)
    Action.create!(
      task: previous_task,
      data_item: data_items[0],
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )

    @task.send(:create_actions_for_data_items)

    assert_equal 4, @task.actions.count
    assert_equal 4, @task.data_items.count
    assert_not_includes @task.data_items, data_items[0]
  end

  test "create_actions_for_data_items is idempotent via unique index" do
    @task.save!
    5.times do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    first_count = @task.send(:create_actions_for_data_items)
    second_count = @task.send(:create_actions_for_data_items)

    assert_equal 5, first_count
    assert_equal 0, second_count
    assert_equal 5, @task.actions.count
  end

  test "actions_count is set after create_actions_for_data_items" do
    @task.save!
    5.times do |i|
      @task.activity.data_items.create!(position: i, data: {content: "Data #{i}"})
    end

    @task.send(:create_actions_for_data_items)
    assert_equal 5, @task.reload.actions_count
  end

  test "actions_completed_count increments when an action completes" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING, started_at: Time.current)
    @task.update_column(:actions_count, @task.actions.count)

    @task.actions.first.update!(progress_status: Task::COMPLETED)

    assert_equal 1, @task.reload.actions_completed_count
  end

  test "calculate_progress returns correct percentage from counters" do
    @task.save!
    @task.update_columns(actions_count: 10, actions_completed_count: 3)
    @task.progress_status = Task::RUNNING

    assert_equal 30, @task.progress
  end

  test "finalize_status produces correct outcome using counters" do
    @task.save!
    create_actions_for_task(@task)
    @task.update!(progress_status: Task::RUNNING, started_at: Time.current)
    @task.update_column(:actions_count, @task.actions.count)

    @task.actions.update_all(progress_status: Task::COMPLETED)
    @task.update_column(:actions_completed_count, @task.actions.count)

    @task.send(:finalize_status)
    assert_equal Task::SUCCEEDED, @task.outcome_status
  end

  test "run acquires a row lock" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )
    activity.tasks.find_by(type: "process_uploaded_files").update!(
      progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED, completed_at: Time.current
    )
    task = activity.tasks.find_by(type: "pre_check_ingest_data")
    activity.data_items.create!(position: 0, data: {objectnumber: "OBJ1"})

    lock_acquired = false
    original_with_lock = task.method(:with_lock)
    task.define_singleton_method(:with_lock) do |&block|
      lock_acquired = true
      original_with_lock.call(&block)
    end
    task.run
    assert lock_acquired
  end

  test "run exits cleanly if another caller wins the race before lock acquired" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )
    activity.tasks.find_by(type: "process_uploaded_files").update!(
      progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED, completed_at: Time.current
    )
    task = activity.tasks.find_by(type: "pre_check_ingest_data")

    # Simulate race: another caller queues the task before we acquire the lock
    original_with_lock = task.method(:with_lock)
    task.define_singleton_method(:with_lock) do |&block|
      update_column(:progress_status, "queued")
      original_with_lock.call(&block)
    end

    task.run
    assert_equal Task::QUEUED, task.reload.progress_status
    assert_equal 0, task.actions.count
  end

  test "run is a no-op when task is already queued" do
    @task.save!
    @task.update!(progress_status: Task::QUEUED)

    assert_nil @task.run
    assert_equal Task::QUEUED, @task.reload.progress_status
  end

  test "run is a no-op when task is already running" do
    @task.save!
    @task.update!(progress_status: Task::RUNNING, started_at: Time.current)

    assert_nil @task.run
    assert_equal Task::RUNNING, @task.reload.progress_status
  end

  test "run is a no-op when dependencies have not succeeded" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )
    dependent_task = activity.tasks.find_by(type: "pre_check_ingest_data")

    assert_nil dependent_task.run
    assert_equal Task::PENDING, dependent_task.reload.progress_status
  end

  test "full orchestration chain: task completes then next task auto-advances to queued" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: true},
      data_config: create_data_config_record_type({record_type: "acquisitions"}),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.find_by(type: "process_uploaded_files")
    second_task = activity.tasks.find_by(type: "pre_check_ingest_data")

    first_task.update!(progress_status: Task::RUNNING, started_at: Time.current)
    activity.data_items.create!(position: 0, data: {objectnumber: "OBJ1"})

    first_task.update!(progress_status: Task::COMPLETED, outcome_status: Task::SUCCEEDED, completed_at: Time.current)

    assert_equal Task::QUEUED, second_task.reload.progress_status
  end

  test "run fails action handler task when there are no processable items" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type(record_type: "acquisitions"),
      files: create_uploaded_files(["test.csv"])
    )
    process_uploaded_files_task = activity.tasks.find_by(type: "process_uploaded_files")
    pre_check_task = activity.tasks.find_by(type: "pre_check_ingest_data")
    process_uploaded_files_task.update!(
      progress_status: Task::COMPLETED,
      outcome_status: Task::SUCCEEDED,
      completed_at: Time.current
    )

    3.times do |i|
      data_item = activity.data_items.create!(position: i, data: {objectnumber: "OBJ#{i}"})
      Action.create!(
        task: process_uploaded_files_task,
        data_item: data_item,
        feedback: {"errors" => [{"type" => "error", "details" => "unprocessable"}]}
      )
    end

    assert pre_check_task.ok_to_run?
    pre_check_task.run

    pre_check_task.reload
    assert pre_check_task.progress_completed?
    assert pre_check_task.outcome_failed?
    assert_includes pre_check_task.feedback_for.errors.map(&:details),
      "Task could not be queued because there were no processable items."
  end
end
