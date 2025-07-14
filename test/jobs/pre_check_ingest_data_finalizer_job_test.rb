require "ostruct"
require "test_helper"

class PreCheckIngestDataFinalizerJobTest < ActiveJob::TestCase
  test "fails task and adds error to feedback if any item jobs failed" do
    successful_first_item_check
    set_up_and_run_task

    # the task will have succeeded, so let's reset it to a failed state
    fail_task(task: @task, indexes: [3])

    assert_performed_with(job: PreCheckIngestDataFinalizerJob, args: [@task]) do
      perform_enqueued_jobs
    end

    @task.reload

    assert_equal "failed", @task.status
    feedback = @task.feedback_for
    errtypes = feedback.errors.map(&:subtype).uniq
    assert_equal [:required_field_value_missing], errtypes
  end

  test "does nothing if all item jobs succeed" do
    successful_first_item_check
    set_up_and_run_task
    @task.reload

    assert_equal "succeeded", @task.status

    feedback = @task.feedback_for
    assert feedback.ok?
    refute feedback.displayable?
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

  # As is only fail one item this way otherwise we can enqueue 2 finalizer jobs.
  # Jobs should be idempotent so that shouldn't be a problem, but worth noting.
  def fail_task(task:, indexes:)
    task.running! # we need to be running to transition status via item processing
    indexes.each do |idx|
      data_item = @task.data_items[idx]
      feedback = data_item.feedback_for
      feedback.add_to_errors(
        subtype: :required_field_value_missing,
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
