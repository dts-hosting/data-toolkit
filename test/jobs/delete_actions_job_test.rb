require "test_helper"

class DeleteActionsJobTest < ActiveJob::TestCase
  setup do
    @activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      files: create_uploaded_files(["test.csv"])
    )
    create_data_items_for_task(@activity.tasks.find_by(type: "pre_check_ingest_data"), 3)
    @activity.data_items.each do |data_item|
      @activity.tasks.find_by(type: "prepare_transfers").actions.create!(data_item: data_item)
    end
    @task = @activity.tasks.find_by(type: "delete_actions")
  end

  test "deletes all actions for the activity and succeeds" do
    other_activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: @activity.data_config,
      files: create_uploaded_files(["test.csv"])
    )
    create_data_items_for_task(other_activity.tasks.find_by(type: "pre_check_ingest_data"), 2)

    assert_equal 6, Action.where(task: @activity.tasks).count

    DeleteActionsJob.perform_now(@task)

    assert_equal 0, Action.where(task: @activity.tasks).count
    assert_equal 2, Action.where(task: other_activity.tasks).count
    assert @task.reload.progress_completed?
    assert @task.outcome_succeeded?
  end

  test "fails the task when deletion raises" do
    Action.stubs(:where).raises(StandardError, "boom")

    DeleteActionsJob.perform_now(@task)

    assert @task.reload.outcome_failed?
    assert @task.feedback_for.errors.any?
  end
end
