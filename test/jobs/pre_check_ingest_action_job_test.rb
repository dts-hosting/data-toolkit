require "ostruct"
require "test_helper"

class PreCheckIngestActionJobTest < ActiveJob::TestCase
  setup do
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create", auto_advance: false},
      files: files
    )
    @data_item = DataItem.create!(
      data: {foo: "bar"},
      position: 101,
      activity: @activity
    )
    @task = @activity.current_task
    @action = Action.create!(task: @task, data_item: @data_item)
  end

  test "job fails if data item check is not ok" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    mock_handler = mock("Handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    mock_handler.stubs(:validate).returns(empty_required_field_response)

    PreCheckIngestActionJob.perform_later(@activity, @action)

    assert_performed_with(job: PreCheckIngestActionJob, args: [@activity, @action]) do
      perform_enqueued_jobs
    end

    @action.reload

    assert_equal Action::COMPLETED, @action.progress_status
    assert @action.feedback_for.errors.any?
  end

  test "job succeeds if pre-checks pass" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    mock_handler = mock("Handler")
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    mock_handler.stubs(:validate).returns(valid_response)

    PreCheckIngestActionJob.perform_later(@activity, @action)

    assert_performed_with(job: PreCheckIngestActionJob, args: [@activity, @action]) do
      perform_enqueued_jobs
    end

    @action.reload

    assert_equal Action::COMPLETED, @action.progress_status
    assert @action.feedback_for.ok?
  end

  private

  def empty_required_field_response = OpenStruct.new(
    valid?: false,
    errors: ["required field empty: objectnumber must be populated"]
  )

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
