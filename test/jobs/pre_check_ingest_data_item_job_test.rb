require "ostruct"
require "test_helper"

class PreCheckIngestDataItemJobTest < ActiveJob::TestCase
  setup do
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      files: files
    )
    task = @activity.tasks.create(type: "Tasks::PreCheckIngestData")
    @data_item = DataItem.create(
      data: {foo: "bar"},
      position: 0,
      activity: @activity,
      current_task_id: task.id
    )
  end

  test "job fails if data item check is not ok" do
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1, only: ProcessUploadedFilesJob

    mock_handler = mock("Handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    mock_handler.stubs(:validate).returns(empty_required_field_response)

    PreCheckIngestDataItemJob.perform_later(@data_item)
    assert_enqueued_jobs 1, only: PreCheckIngestDataItemJob

    perform_enqueued_jobs
    @data_item.reload

    assert_equal "failed", @data_item.status
  end

  test "job succeeds if pre-checks pass" do
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1

    mock_handler = mock("Handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    mock_handler.stubs(:validate).returns(valid_response)

    PreCheckIngestDataItemJob.perform_later(@data_item)
    assert_enqueued_jobs 1, only: PreCheckIngestDataItemJob

    perform_enqueued_jobs
    @data_item.reload

    assert_equal "succeeded", @data_item.status
    assert @data_item.feedback_for.ok?
  end

  private

  def empty_required_field_response = OpenStruct.new(
    valid?: false,
    errors: ["required field empty: objectnumber must be populated"]
  )

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
