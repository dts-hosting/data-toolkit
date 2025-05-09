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
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .raises(CollectionSpace::Mapper::NoClientServiceError.new("rectype"))

    assert @task.ok_to_run?
    @task.run
    perform_enqueued_jobs
    @task.reload
    assert_equal "failed", @task.status
    assert_includes @task.feedback["errors"]["application error"],
      "collectionspace-client does not have a service configured " \
        "for rectype"
  end

  test "job fails when no record_type DataConfig id_field" do
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .raises(CollectionSpace::Mapper::IdFieldNotInMapperError)

    assert @task.ok_to_run?
    @task.run
    perform_enqueued_jobs
    @task.reload
    assert_equal "failed", @task.status
    assert_includes @task.feedback["errors"]["application error"],
      "cannot determine the unique ID field for this record type from " \
      "DataConfig"
  end

  test "job fails if first data item check is not ok" do
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1

    mock_handler = mock
    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns(mock_handler)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:call).returns(true)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(false)
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:feedback).returns({
        messages: {},
        warnings: {},
        errors: {"One or more headers in spreadsheet are empty" => []}
      })

    @task.run
    perform_enqueued_jobs
    @task.reload
    assert_equal "failed", @task.status
    assert @task.feedback["errors"].key?("One or more headers in spreadsheet " \
                                         "are empty")
  end

  test "job spawns DataItem jobs if pre-checks pass" do
    assert_performed_jobs 0
    perform_enqueued_jobs
    assert_performed_jobs 1

    CollectionSpaceMapper.stubs(:single_record_type_handler_for)
      .returns("handler")
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(true)

    @task.run
    perform_enqueued_jobs
    assert_enqueued_jobs 10
  end
end
