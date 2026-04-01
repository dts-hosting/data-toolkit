require "test_helper"

class TaskOrchestratorTest < ActiveSupport::TestCase
  def setup
    activity = create_activity
    @task = activity.tasks.create!(type: :pre_check_ingest_data)
    @task.update!(progress_status: Task::RUNNING, started_at: Time.current)
  end

  test "increments counter when action first completes" do
    create_actions_for_task(@task, 5)

    @task.actions.first.update!(progress_status: Action::COMPLETED)

    assert_equal 1, @task.reload.actions_completed_count
  end

  test "does not increment counter if task is already completed" do
    create_actions_for_task(@task, 2)

    # Complete task directly
    @task.done!(Task::SUCCEEDED)
    original_count = @task.reload.actions_completed_count

    # Now complete an action — orchestrator should skip
    @task.actions.first.update!(progress_status: Action::COMPLETED)

    assert_equal original_count, @task.reload.actions_completed_count
  end

  test "finalizes task as succeeded when all actions complete without errors" do
    create_actions_for_task(@task, 3)

    # Complete first two via update_all (bypasses callbacks)
    @task.actions.limit(2).update_all(progress_status: Action::COMPLETED)
    @task.update_column(:actions_completed_count, 2)

    # Complete last one via update to trigger orchestrator
    @task.actions.last.update!(progress_status: Action::COMPLETED)

    @task.reload
    assert_equal Task::COMPLETED, @task.progress_status
    assert_equal Task::SUCCEEDED, @task.outcome_status
    assert_not_nil @task.completed_at
  end

  test "finalizes task as failed when all actions have errors" do
    create_actions_for_task(@task, 3)

    feedback = {"errors" => [{"type" => "error", "details" => "test"}]}

    @task.actions.limit(2).update_all(progress_status: Action::COMPLETED, feedback: feedback)
    @task.update_column(:actions_completed_count, 2)

    @task.actions.last.update!(progress_status: Action::COMPLETED, feedback: feedback)

    @task.reload
    assert_equal Task::COMPLETED, @task.progress_status
    assert_equal Task::FAILED, @task.outcome_status
  end

  test "finalizes task as review when some actions have errors" do
    create_actions_for_task(@task, 3)

    feedback = {"errors" => [{"type" => "error", "details" => "test"}]}

    @task.actions.limit(2).update_all(progress_status: Action::COMPLETED)
    @task.update_column(:actions_completed_count, 2)

    @task.actions.last.update!(progress_status: Action::COMPLETED, feedback: feedback)

    @task.reload
    assert_equal Task::COMPLETED, @task.progress_status
    assert_equal Task::REVIEW, @task.outcome_status
  end

  test "finalizes task as review when actions have warnings" do
    create_actions_for_task(@task, 3)

    @task.actions.limit(2).update_all(progress_status: Action::COMPLETED)
    @task.update_column(:actions_completed_count, 2)

    @task.actions.last.update!(
      progress_status: Action::COMPLETED,
      feedback: {"warnings" => [{"type" => "warning", "details" => "test"}]}
    )

    @task.reload
    assert_equal Task::COMPLETED, @task.progress_status
    assert_equal Task::REVIEW, @task.outcome_status
  end

  test "broadcasts progress when task is not yet complete" do
    create_actions_for_task(@task, 5)

    action = @task.actions.first
    # Force broadcast by stubbing rand to return 0 (always < checkin_frequency)
    action.stub :rand, 0 do
      action.stub :broadcast_action_to, nil do
        action.update!(progress_status: Action::COMPLETED)
      end
    end

    assert_equal 1, @task.reload.actions_completed_count
    assert_equal Task::RUNNING, @task.progress_status
  end

  test "does not broadcast when random gate is not met" do
    create_actions_for_task(@task, 5)

    action = @task.actions.first
    broadcast_called = false

    action.define_singleton_method(:broadcast_action_to) do |*_args, **_kwargs|
      broadcast_called = true
    end

    # Stub rand to return 1.0 (always >= checkin_frequency)
    TaskOrchestrator.stub(:new, ->(_action) {
      orchestrator = TaskOrchestrator.allocate
      orchestrator.instance_variable_set(:@action, action)
      orchestrator.instance_variable_set(:@task, action.task)
      orchestrator.define_singleton_method(:rand) { 1.0 }
      orchestrator
    }) do
      action.update!(progress_status: Action::COMPLETED)
    end

    refute broadcast_called
  end

  test "end-to-end: last action completes and triggers activity auto-advance" do
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

    # Create an action for the first task and complete it via orchestrator
    action = first_task.actions.create!(
      data_item: activity.data_items.first
    )
    first_task.update_columns(actions_count: 1, actions_completed_count: 0)

    action.update!(progress_status: Action::COMPLETED)

    first_task.reload
    assert_equal Task::COMPLETED, first_task.progress_status
    assert_equal Task::SUCCEEDED, first_task.outcome_status

    second_task.reload
    assert_equal Task::QUEUED, second_task.progress_status
  end
end
