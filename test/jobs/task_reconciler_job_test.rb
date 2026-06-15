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
    @files_task = @activity.tasks.find { |t| t.type == "process_uploaded_files" }
  end

  teardown do
    SolidQueue::Job.delete_all
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

  test "finalizes an all-completed running task before checking live jobs" do
    @task.actions.update_all(progress_status: Progressable::COMPLETED)
    # leave actions_completed_count stale at 0; finalize! must recompute
    stub_live_jobs(true) # would block the orphan sweep path if reached

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_completed?
    assert @task.outcome_succeeded?
  end

  test "a live action job for this activity blocks reconciliation" do
    create_live_job(PreCheckIngestActionJob.new(@activity, @task.actions.first))

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_running?
    @task.actions.each { |a| assert a.progress_pending? }
  end

  test "a live action job for another activity does not block reconciliation" do
    other = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      data_config: create_data_config_record_type(record_type: "other_activity_records"),
      files: create_uploaded_files(["test.csv"])
    )
    other_task = other.tasks.find { |t| t.type == "pre_check_ingest_data" }
    create_actions_for_task(other_task, 1)
    create_live_job(PreCheckIngestActionJob.new(other, other_task.actions.first))

    TaskReconcilerJob.perform_now

    @task.reload
    assert @task.progress_completed?
    @task.actions.each { |a| assert a.progress_completed? }
  end

  test "fails an orphaned handler-only running task" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    @files_task.update_columns(
      progress_status: Progressable::RUNNING,
      started_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )

    TaskReconcilerJob.perform_now

    @files_task.reload
    assert @files_task.progress_completed?
    assert @files_task.outcome_failed?
    assert_equal [:application_error], @files_task.feedback_for.errors.map(&:subtype)
  end

  test "skips a handler-only running task with a live handler job" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    @files_task.update_columns(
      progress_status: Progressable::RUNNING,
      started_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )
    create_live_job(ProcessUploadedFilesJob.new(@files_task))

    TaskReconcilerJob.perform_now

    assert @files_task.reload.progress_running?
  end

  test "re-enqueues a stale queued task with no live handler job" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    @files_task.update_columns(
      progress_status: Progressable::QUEUED,
      updated_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )

    assert_enqueued_with(job: ProcessUploadedFilesJob, args: [@files_task]) do
      TaskReconcilerJob.perform_now
    end

    assert @files_task.reload.progress_queued?
  end

  test "leaves a fresh queued task alone" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    # @files_task is queued with a fresh updated_at via start_workflow

    assert_no_enqueued_jobs(only: ProcessUploadedFilesJob) do
      TaskReconcilerJob.perform_now
    end

    assert @files_task.reload.progress_queued?
  end

  test "leaves a stale queued task with a live handler job alone" do
    @task.update_column(:progress_status, Progressable::COMPLETED)
    @files_task.update_columns(
      progress_status: Progressable::QUEUED,
      updated_at: (TaskReconcilerJob::GRACE_PERIOD + 1.minute).ago
    )
    create_live_job(ProcessUploadedFilesJob.new(@files_task))

    assert_no_enqueued_jobs(only: ProcessUploadedFilesJob) do
      TaskReconcilerJob.perform_now
    end

    assert @files_task.reload.progress_queued?
  end

  private

  def stub_live_jobs(value)
    TaskReconcilerJob.any_instance.stubs(:live_action_jobs?).returns(value)
  end

  # Mirrors how SolidQueue stores an enqueued-but-unfinished job: the full
  # ActiveJob serialization (GlobalIDs included) in the arguments column.
  def create_live_job(job)
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: job.class.name,
      arguments: job.serialize
    )
  end
end
