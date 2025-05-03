require "test_helper"

class PreCheckIngestDataFinalizerJobTest < ActiveJob::TestCase
  test "fails task and adds error to feedback if any item jobs failed" do
    successful_first_item_check
    set_up_and_run_task
    perform_enqueued_jobs # item jobs, should all succeed
    fail_items([3, 5])
    @task.update_progress
    perform_enqueued_jobs # finalizer job
    @task.reload

    assert_equal "failed", @task.status
    assert @task.feedback.key?("errors")
  end

  test "does nothing if all item jobs succeed" do
    successful_first_item_check
    set_up_and_run_task
    perform_enqueued_jobs # item jobs, should all succeed
    @task.update_progress
    perform_enqueued_jobs # finalizer job
    @task.reload

    assert_equal "succeeded", @task.status
    assert_nil @task.feedback
  end

  test "does not run if pre-item checks fail" do
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(false)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:feedback).returns({
        messages: {},
        warnings: {},
        errors: {"One or more headers in spreadsheet are empty" => []}
      })
    set_up_and_run_task
    @task.reload
    @task.update_progress

    assert_enqueued_jobs 0 # finalizer job
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
    @activity.save
    @task = @activity.tasks.find do |t|
      t.type == "Tasks::PreCheckIngestData"
    end
    perform_enqueued_jobs # ProcessUploadedFilesJob
    handler = mock
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(handler)
    IngestDataPreCheckItem.any_instance
      .stubs(:ok?).returns(true)
    @task.run
    perform_enqueued_jobs # PreCheckIngestDataJob
  end

  def fail_items(indexes)
    indexes.each do |idx|
      @task.data_items[idx]
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
  end
end
