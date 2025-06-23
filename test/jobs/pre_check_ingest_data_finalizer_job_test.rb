require "test_helper"

class PreCheckIngestDataFinalizerJobTest < ActiveJob::TestCase
  test "fails task and adds error to feedback if any item jobs failed" do
    successful_first_item_check
    set_up_and_run_task

    # the task will have succeeded, so let's reset it to a failed state
    fail_task(task: @task, indexes: [3, 5])

    assert_performed_with(job: PreCheckIngestDataFinalizerJob, args: [@task]) do
      perform_enqueued_jobs
    end

    @task.reload

    assert_equal "failed", @task.status
    assert @task.feedback.key?("data item failures")
  end

  test "does nothing if all item jobs succeed" do
    successful_first_item_check
    set_up_and_run_task
    @task.reload

    assert_equal "succeeded", @task.status
    assert_nil @task.feedback
  end

  test "does not run if pre-item checks fail" do
    skip "TODO: review purpose, finalizer job always runs when task complete"

    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(false)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:feedback).returns({
        messages: {},
        warnings: {},
        errors: {"One or more headers in spreadsheet are empty" => []}
      })
    set_up_and_run_task

    assert_enqueued_jobs 0, only: PreCheckIngestDataFinalizerJob # finalizer job
  end

  private

  def successful_first_item_check
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(true)
  end

  def set_up_and_run_task
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity({
      type: Activities::CreateOrUpdateRecords,
      config: {action: "create"},
      files: files
    })

    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    handler = mock
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(handler)
    IngestDataPreCheckItem.any_instance
      .stubs(:ok?).returns(true)

    @task = @activity.next_task
    @task.run
    assert_performed_with(job: PreCheckIngestDataJob, args: [@task]) do
      assert_performed_with(job: PreCheckIngestDataFinalizerJob, args: [@task]) do
        perform_enqueued_jobs
      end
    end
  end

  def fail_task(task:, indexes:)
    indexes.each do |idx|
      task.data_items[idx]
        .update!(
          status: "failed",
          feedback: {
            messages: {},
            warnings: {},
            errors: {"Empty required field(s)" =>
                     ["objectnumber must be populated"]}
          }
        )
    end
    task.running! # we need to be running to transition using update_progress
    task.update_progress
  end
end
