require "test_helper"

class TaskReconcilerJobTest < ActiveJob::TestCase
  setup do
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      files: files
    )
    @task = @activity.tasks.find { |t| t.type == "pre_check_ingest_data" }
    create_actions_for_task(@task, 3)
    @task.update_columns(
      progress_status: Progressable::RUNNING,
      started_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )
  end

  test "finalizes task when no live action jobs exist" do
    stub_live_jobs(false)

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_completed?
    @task.actions.each do |action|
      assert action.progress_completed?
      assert_equal [:application_error], action.feedback_for.errors.map(&:subtype)
    end
  end

  test "skips task still within grace period" do
    @task.update_column(:started_at, 1.minute.ago)
    stub_live_jobs(false)

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_running?
    @task.actions.each { |a| assert a.progress_pending? }
  end

  test "skips task when a live action job exists" do
    stub_live_jobs(true)

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_running?
  end

  test "skips tasks without an action_handler" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    files_task = @activity.tasks.find { |t| t.type == "process_uploaded_files" }
    files_task.update_columns(
      progress_status: Progressable::RUNNING,
      started_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )
    stub_live_jobs(false)

    TaskReconcilerJob.perform_now

    files_task.reload
    assert files_task.progress_running?
  end

  private

  def stub_live_jobs(value)
    TaskReconcilerJob.any_instance.stubs(:live_action_jobs?).returns(value)
  end
end
