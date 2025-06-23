require "test_helper"

class PreCheckIngestDataItemJobTest < ActiveJob::TestCase
  setup do
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      files: files
    )
    @data_item = DataItem.create(
      data: {foo: "bar"},
      position: 0,
      activity: @activity,
      current_task: @activity.current_task
    )
  end

  test "job fails if data item check is not ok" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock)
    IngestDataPreCheckItem.any_instance.stubs(:ok?).returns(false)
    IngestDataPreCheckItem.any_instance.stubs(:feedback).returns({
      messages: {},
      warnings: {},
      errors: {"Empty required field(s)" => ["objectnumber must be populated"]}
    })

    PreCheckIngestDataItemJob.perform_later(@data_item)

    assert_performed_with(job: PreCheckIngestDataItemJob, args: [@data_item]) do
      perform_enqueued_jobs
    end

    @data_item.reload

    assert_equal "failed", @data_item.status
    assert @data_item.feedback["errors"].key?("Empty required field(s)")
  end

  test "job succeeds if pre-checks pass" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock)
    IngestDataPreCheckItem.any_instance.stubs(:ok?).returns(true)

    PreCheckIngestDataItemJob.perform_later(@data_item)

    assert_performed_with(job: PreCheckIngestDataItemJob, args: [@data_item]) do
      perform_enqueued_jobs
    end

    @data_item.reload

    assert_equal "succeeded", @data_item.status
    assert_nil @data_item.feedback
  end
end
