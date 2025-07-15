require "test_helper"

class PreCheckIngestDataJobTest < ActiveJob::TestCase
  setup do
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
  end

  test "job fails when service not configured" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .raises(CollectionSpace::Mapper::NoClientServiceError.new("rectype"))

    assert @task.ok_to_run?
    @task.run

    assert_performed_with(job: PreCheckIngestDataJob, args: [@task]) do
      perform_enqueued_jobs
    end

    @task.reload
    assert_equal "failed", @task.status

    feedback = @task.feedback_for
    assert_equal feedback.errors.map(&:subtype), [:application_error]
    assert_equal feedback.errors.map(&:details),
      ["collectionspace-client does not have a service configured " \
        "for rectype"]
  end

  test "job fails when no record_type DataConfig id_field" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .raises(CollectionSpace::Mapper::IdFieldNotInMapperError)

    assert @task.ok_to_run?
    @task.run

    assert_performed_with(job: PreCheckIngestDataJob, args: [@task]) do
      perform_enqueued_jobs
    end

    @task.reload
    assert_equal "failed", @task.status
    feedback = @task.feedback_for
    assert_equal feedback.errors.map(&:subtype), [:application_error]
    assert_equal feedback.errors.map(&:details),
      ["cannot determine the unique ID field for this record type from " \
      "DataConfig"]
  end

  test "job fails if first data item check is not ok" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    mock_handler = mock
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:call).returns(true)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(false)

    @task.run

    assert_performed_with(job: PreCheckIngestDataJob, args: [@task]) do
      perform_enqueued_jobs
    end

    @task.reload
    assert_equal "failed", @task.status
  end

  test "job spawns DataItem jobs if pre-checks pass" do
    assert_performed_with(job: ProcessUploadedFilesJob, args: [@activity.current_task]) do
      perform_enqueued_jobs
    end

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns("handler")
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(true)

    @task.run

    assert_performed_with(job: PreCheckIngestDataJob, args: [@task]) do
      assert_performed_jobs 11, only: [PreCheckIngestDataJob, PreCheckIngestDataItemJob] do
        perform_enqueued_jobs
      end
    end
  end
end
