require "test_helper"

class WorkflowManagerTest < ActiveSupport::TestCase
  def setup
    activity = create_activity
    @task = activity.tasks.create!(type: :pre_check_ingest_data)
    @task.update!(progress_status: Task::RUNNING, started_at: Time.current)
  end

  test "complete_action does not increment counter if task is already completed" do
    create_actions_for_task(@task, 2)

    WorkflowManager.complete_task(@task, outcome: Task::SUCCEEDED)
    original_count = @task.reload.actions_completed_count

    WorkflowManager.complete_action(@task.actions.first)

    assert_equal original_count, @task.reload.actions_completed_count
  end

  test "complete_action only increments counter on first completion" do
    create_actions_for_task(@task, 2)

    action = @task.actions.first

    WorkflowManager.complete_action(action)
    WorkflowManager.complete_action(action, feedback: {"errors" => []})

    assert_equal 1, @task.reload.actions_completed_count
    assert_equal Task::RUNNING, @task.progress_status
  end

  test "duplicate complete_action does not broadcast progress again" do
    create_actions_for_task(@task, 5)

    action = @task.actions.first
    broadcast_count = 0
    action.define_singleton_method(:broadcast_action_to) do |*_args, **_kwargs|
      broadcast_count += 1
    end
    Task.any_instance.stubs(:checkin_frequency).returns(1.1)

    WorkflowManager.complete_action(action)
    WorkflowManager.complete_action(action)

    assert_equal 1, broadcast_count
    assert_equal 1, @task.reload.actions_completed_count
  end

  test "start_workflow runs first workflow task" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type(record_type: "start_workflow_records"),
      files: create_uploaded_files(["test.csv"])
    )

    first_task = activity.tasks.find_by(type: "process_uploaded_files")

    WorkflowManager.expects(:run_task).with(first_task).once

    WorkflowManager.start_workflow(activity)
  end

  test "start_workflow does nothing when workflow has no tasks" do
    activity = create_activity(
      type: :export_record_ids,
      data_config: create_data_config_record_type(record_type: "empty_workflow_records")
    )

    WorkflowManager.expects(:run_task).never

    WorkflowManager.start_workflow(activity)
  end

  test "start_workflow is a no-op when first task has already started" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type(record_type: "already_started_workflow_records"),
      files: create_uploaded_files(["test.csv"])
    )
    first_task = activity.tasks.find_by(type: "process_uploaded_files")

    assert_equal Task::QUEUED, first_task.progress_status
    ProcessUploadedFilesJob.expects(:perform_later).never

    WorkflowManager.start_workflow(activity)

    assert_equal Task::QUEUED, first_task.reload.progress_status
  end

  test "start_workflow is a no-op when first task has already completed" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type(record_type: "completed_workflow_records"),
      files: create_uploaded_files(["test.csv"])
    )
    first_task = activity.tasks.find_by(type: "process_uploaded_files")
    first_task.update!(
      progress_status: Task::COMPLETED,
      outcome_status: Task::SUCCEEDED,
      started_at: Time.current,
      completed_at: Time.current
    )

    ProcessUploadedFilesJob.expects(:perform_later).never

    WorkflowManager.start_workflow(activity)

    assert first_task.reload.progress_completed?
  end

  test "complete_task only advances activity on first completion" do
    finalizer_calls = 0
    finalizer = Object.new
    finalizer.define_singleton_method(:perform_later) do |_task|
      finalizer_calls += 1
    end

    activity = @task.activity
    activity.stub :current_task, @task do
      @task.stub :finalizer, finalizer do
        WorkflowManager.complete_task(@task, outcome: Task::FAILED)
        WorkflowManager.complete_task(@task, outcome: Task::FAILED)
      end
    end

    assert_equal 1, finalizer_calls
  end

  test "complete_action broadcasts progress when checkin gate fires" do
    create_actions_for_task(@task, 5)

    action = @task.actions.first
    broadcast_called = false
    action.define_singleton_method(:broadcast_action_to) do |*_args, **_kwargs|
      broadcast_called = true
    end

    # Force the rand < checkin_frequency check to always pass
    Task.any_instance.stubs(:checkin_frequency).returns(1.1)

    WorkflowManager.complete_action(action)

    assert broadcast_called
    assert_equal 1, @task.reload.actions_completed_count
    assert_equal Task::RUNNING, @task.progress_status
  end

  test "complete_action does not broadcast when checkin gate is not met" do
    create_actions_for_task(@task, 5)

    action = @task.actions.first
    broadcast_called = false
    action.define_singleton_method(:broadcast_action_to) do |*_args, **_kwargs|
      broadcast_called = true
    end

    # Force the rand < checkin_frequency check to never pass
    Task.any_instance.stubs(:checkin_frequency).returns(0)

    WorkflowManager.complete_action(action)

    refute broadcast_called
    assert_equal 1, @task.reload.actions_completed_count
    assert_equal Task::RUNNING, @task.progress_status
  end

  test "requeue_task re-runs a queued task" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type(record_type: "requeue_records"),
      files: create_uploaded_files(["test.csv"])
    )
    first_task = activity.tasks.find_by(type: "process_uploaded_files")
    assert_equal Task::QUEUED, first_task.progress_status

    ProcessUploadedFilesJob.expects(:perform_later).with(first_task).once

    WorkflowManager.requeue_task(first_task)

    assert first_task.reload.progress_queued?
  end

  test "requeue_task is a no-op for a task that is not queued" do
    PreCheckIngestDataJob.expects(:perform_later).never

    WorkflowManager.requeue_task(@task)

    assert @task.reload.progress_running?
  end

  test "run_task re-runs a task whose actions already exist instead of failing" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create"},
      data_config: create_data_config_record_type(record_type: "rerun_records"),
      files: create_uploaded_files(["test.csv"])
    )
    activity.tasks.find_by(type: "process_uploaded_files").update!(
      progress_status: Task::COMPLETED,
      outcome_status: Task::SUCCEEDED,
      completed_at: Time.current
    )
    pre_check_task = activity.tasks.find_by(type: "pre_check_ingest_data")
    create_data_items_for_task(pre_check_task, 3)

    PreCheckIngestDataJob.expects(:perform_later).with(pre_check_task).once

    WorkflowManager.run_task(pre_check_task)

    pre_check_task.reload
    assert pre_check_task.progress_queued?
    assert_equal 3, pre_check_task.actions_count
  end

  test "run_task no-items failure advances only once" do
    activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: true},
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

    finalizer_calls = 0
    finalizer = Object.new
    finalizer.define_singleton_method(:perform_later) do |_task|
      finalizer_calls += 1
    end

    Activity.any_instance.stubs(:current_task).returns(pre_check_task)
    pre_check_task.activity.stub :current_task, pre_check_task do
      pre_check_task.stub :finalizer, finalizer do
        WorkflowManager.run_task(pre_check_task)
        WorkflowManager.run_task(pre_check_task)
      end
    end

    assert_equal 1, finalizer_calls
    assert pre_check_task.reload.progress_completed?
    assert pre_check_task.outcome_failed?
  end
end
