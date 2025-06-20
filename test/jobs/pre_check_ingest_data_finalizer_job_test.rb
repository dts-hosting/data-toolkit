require "ostruct"
require "test_helper"

class PreCheckIngestDataFinalizerJobTest < ActiveJob::TestCase
  test "fails task and adds error to feedback if any item jobs failed" do
    set_up_and_run_task_with_item_failures
    perform_enqueued_jobs # item jobs, should all succeed
    fail_items([3, 5]) # then we manually fail them to test
    @task.update_progress
    perform_enqueued_jobs # finalizer job
    @task.reload

    assert_equal "failed", @task.status
    # debugger
    # assert @task.feedback.key?("errors")
  end

  test "does nothing if all item jobs succeed" do
    # successful_first_item_check
    set_up_and_run_task_with_no_item_failures
    perform_enqueued_jobs # item jobs, should all succeed
    @task.update_progress
    perform_enqueued_jobs # finalizer job
    @task.reload
    assert_equal "succeeded", @task.status
    feedback = @task.feedback_for

    assert feedback.ok?
    refute feedback.displayable?
  end

  test "does not run if pre-item checks fail" do
    set_up_and_run_task_with_first_item_failure
    @task.reload
    @task.update_progress

    assert_enqueued_jobs 0 # finalizer job
  end

  private

  def set_up_and_run_task_with_no_item_failures
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
    handler = mock("mock_handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(handler)
    IngestDataPreCheckItem.any_instance
      .stubs(:ok?).returns(true)
    handler.stubs(:check_fields).returns(
      {known_fields: %w[objectnumber title],
       unknown_fields: []}
    )
    handler.stubs(:validate).returns(valid_response)
    @task.run
    perform_enqueued_jobs # PreCheckIngestDataJob
  end

  def set_up_and_run_task_with_item_failures
    files = create_uploaded_files(["empty_required_values.csv"])
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
    handler = mock("mock_handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(handler)
    IngestDataPreCheckItem.any_instance
      .stubs(:ok?).returns(true)
    handler.stubs(:check_fields).returns(
      {known_fields: %w[objectnumber title],
       unknown_fields: []}
    )
    handler.stubs(:validate).returns(valid_response)
    @task.run
    perform_enqueued_jobs # PreCheckIngestDataJob
  end

  def set_up_and_run_task_with_first_item_failure
    files = create_uploaded_files(["empty_column_header.csv"])
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
    handler = mock("mock_handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(handler)
    @task.run
    perform_enqueued_jobs # PreCheckIngestDataJob
  end

  def fail_items(indexes)
    indexes.each do |idx|
      data_item = @task.data_items[idx]
      feedback = data_item.feedback_for
      feedback.add_to_errors(
        subtype: :required_field_missing,
        details: ["objectnumber must be populated"]
      )
      data_item.update!(
        status: "failed",
        feedback: feedback
      )
    end
  end

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
