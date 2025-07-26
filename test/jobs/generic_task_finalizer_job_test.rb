require "ostruct"
require "test_helper"

class GenericTaskFinalizerJobTest < ActiveJob::TestCase
  test "fails task and adds error to feedback if any item jobs failed" do
    successful_first_item_check
    set_up_and_run_task

    # the task will have succeeded, so let's reset it to a failed state
    fail_task(task: @task, indexes: [3, 5])

    assert_performed_with(job: GenericTaskFinalizerJob, args: [@task]) do
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

  private

  def successful_first_item_check
    IngestDataPreCheckFirstItem.any_instance
      .stubs(:ok?).returns(true)
  end

  def set_up_and_run_task
    files = create_uploaded_files(["test.csv"])
    @activity = create_activity({
      type: Activities::CreateOrUpdateRecords,
      config: {action: "create", auto_advance: false},
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
      assert_performed_with(job: GenericTaskFinalizerJob, args: [@task]) do
        perform_enqueued_jobs
      end
    end
  end

  def fail_task(task:, indexes:)
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
    task.fail!
  end

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
