require "test_helper"

class GenericQueueActionJobTest < ActiveJob::TestCase
  class NotReadyQueueJob < GenericQueueActionJob
    private

    def ready?(task, feedback)
      feedback.add_to_errors(subtype: :application_error, details: "not ready")
      false
    end
  end

  setup do
    @activity = create_activity(
      type: :check_media_derivatives,
      config: {auto_advance: false},
      data_config: create_data_config_record_type(record_type: "media"),
      files: create_uploaded_files(["test.csv"])
    )
    @task = @activity.tasks.find_by(type: "process_media_derivatives")
    create_data_items_for_task(@task, 3)
  end

  test "queues one action_handler job per action" do
    GenericQueueActionJob.perform_now(@task)

    assert @task.reload.progress_running?
    @task.actions.each do |action|
      assert_enqueued_with(job: ProcessMediaDerivativesActionJob, args: [@activity, action])
    end
  end

  test "fails the task with feedback when ready? returns false" do
    NotReadyQueueJob.perform_now(@task)

    @task.reload
    assert_equal Task::FAILED, @task.status
    assert_equal ["not ready"], @task.feedback_for.errors.map(&:details)
    assert_no_enqueued_jobs(only: ProcessMediaDerivativesActionJob)
  end

  test "fails the task when queueing raises" do
    ActiveJob.stubs(:perform_all_later).raises(StandardError, "queue down")

    GenericQueueActionJob.perform_now(@task)

    @task.reload
    assert_equal Task::FAILED, @task.status
    assert_equal [:application_error], @task.feedback_for.errors.map(&:subtype)
  end
end
