require "test_helper"

class ActionTest < ActiveSupport::TestCase
  setup do
    activity = create_activity
    @task = activity.tasks.create!(type: :pre_check_ingest_data)
    @data_item = activity.data_items.create!(position: 0, data: {objectNumber: "123"})
    @action = Action.new(task: @task, data_item: @data_item)
  end

  test "valid action" do
    assert @action.valid?
  end

  test "requires task" do
    @action.task = nil
    refute @action.valid?
    assert_includes @action.errors[:task], "must exist"
  end

  test "requires data_item" do
    @action.data_item = nil
    refute @action.valid?
    assert_includes @action.errors[:data_item], "must exist"
  end

  test "has default progress_status of pending" do
    action = Action.new
    assert_equal Action::PENDING, action.progress_status
  end

  test "should allow valid progress_status values" do
    %w[pending queued running completed].each do |status|
      @action.progress_status = status
      assert @action.valid?, "#{status} should be a valid progress_status"
    end
  end

  test "should enforce uniqueness of task_id scoped to data_item_id" do
    @action.save!
    duplicate_action = Action.new(task: @task, data_item: @data_item)
    refute duplicate_action.valid?
    assert_includes duplicate_action.errors[:task_id], "has already been taken"
  end

  test "should allow same data_item with different tasks" do
    @action.save!
    other_task = @task.activity.tasks.find_or_create_by!(type: :process_media_derivatives)
    other_action = Action.new(task: other_task, data_item: @data_item)
    assert other_action.valid?
  end

  test "should allow same task with different data_items" do
    @action.save!
    other_data_item = @task.activity.data_items.create!(position: 1, data: {objectNumber: "456"})
    other_action = Action.new(task: @task, data_item: other_data_item)
    assert other_action.valid?
  end

  # Feedback tests
  test "should store feedback as JSON" do
    feedback_hash = {
      "errors" => [{"type" => "error", "details" => "test error"}],
      "warnings" => [],
      "messages" => []
    }
    @action.feedback = feedback_hash
    @action.save!
    @action.reload

    assert_equal feedback_hash, @action.feedback
  end

  test "with_errors scope should find actions with errors" do
    action_with_errors = Action.create!(
      task: @task,
      data_item: @data_item,
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )

    other_data_item = @task.activity.data_items.create!(position: 1, data: {objectNumber: "456"})
    action_without_errors = Action.create!(
      task: @task,
      data_item: other_data_item,
      feedback: {"errors" => []}
    )

    assert_includes Action.with_errors, action_with_errors
    assert_not_includes Action.with_errors, action_without_errors
  end

  test "without_errors scope should find actions without errors" do
    action_with_errors = Action.create!(
      task: @task,
      data_item: @data_item,
      feedback: {"errors" => [{"type" => "error", "details" => "test"}]}
    )

    other_data_item = @task.activity.data_items.create!(position: 1, data: {objectNumber: "456"})
    action_without_errors = Action.create!(
      task: @task,
      data_item: other_data_item,
      feedback: {"errors" => []}
    )

    assert_not_includes Action.without_errors, action_with_errors
    assert_includes Action.without_errors, action_without_errors
  end

  test "with_warnings scope should find actions with warnings" do
    action_with_warnings = Action.create!(
      task: @task,
      data_item: @data_item,
      feedback: {"warnings" => [{"type" => "warning", "details" => "test"}]}
    )

    other_data_item = @task.activity.data_items.create!(position: 1, data: {objectNumber: "456"})
    action_without_warnings = Action.create!(
      task: @task,
      data_item: other_data_item,
      feedback: {"warnings" => []}
    )

    assert_includes Action.with_warnings, action_with_warnings
    assert_not_includes Action.with_warnings, action_without_warnings
  end

  # Status transition tests
  test "start! should update progress_status and started_at" do
    @action.save!
    @action.start!

    assert_equal Action::RUNNING, @action.progress_status
    assert_not_nil @action.started_at
  end

  test "done! should update progress_status and completed_at" do
    @action.save!
    @action.done!

    assert_equal Action::COMPLETED, @action.progress_status
    assert_not_nil @action.completed_at
  end

  test "done! should accept feedback" do
    feedback_hash = {
      "errors" => [{"type" => "error", "details" => "test error"}]
    }
    @action.save!
    @action.done!(feedback_hash)

    assert_equal Action::COMPLETED, @action.progress_status
    assert_not_nil @action.completed_at
    assert_equal feedback_hash, @action.feedback
  end

  # Feedbackable concern tests
  test "should provide feedback_context from task" do
    @action.save!
    assert_equal @task.feedback_context, @action.feedback_context
  end

  test "feedback_for should return Feedback object" do
    @action.save!
    feedback = @action.feedback_for
    assert_instance_of Feedback, feedback
  end

  # Progressable concern tests
  test "should respond to progress status predicates" do
    @action.save!

    @action.progress_status = Action::PENDING
    assert @action.progress_pending?

    @action.progress_status = Action::QUEUED
    assert @action.progress_queued?

    @action.progress_status = Action::RUNNING
    assert @action.progress_running?

    @action.progress_status = Action::COMPLETED
    assert @action.progress_completed?
  end

  # Callback tests
  test "after_update_commit should touch task when progress reaches 100%" do
    @action.save!
    # Create 4 more actions (we already have 1 from setup)
    4.times do |i|
      data_item = @task.activity.data_items.create!(position: i + 1, data: {objectNumber: (i + 2).to_s})
      @task.actions.create!(data_item: data_item)
    end
    @task.update!(progress_status: Task::RUNNING)

    # Complete all actions
    @task.actions.update_all(progress_status: Action::COMPLETED)

    # Update the last one to trigger the callback
    last_action = @task.actions.last
    original_task_updated_at = @task.updated_at

    # Wait a bit to ensure timestamp difference
    sleep 0.01
    last_action.update(progress_status: Action::COMPLETED)

    @task.reload
    assert @task.updated_at > original_task_updated_at, "Task should have been touched"
  end
end
