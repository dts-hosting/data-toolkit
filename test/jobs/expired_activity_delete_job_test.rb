require "test_helper"

class ExpiredActivityDeleteJobTest < ActiveJob::TestCase
  setup do
    @data_config = create_data_config_record_type
    # we'll force this one to be expired
    @expired_activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )
    # this one should not be expired
    @recent_activity = create_activity(
      type: "Activities::CreateOrUpdateRecords",
      config: {action: "create"},
      data_config: @data_config,
      files: create_uploaded_files(["test.csv"])
    )
  end

  test "deletes expired failed activities" do
    # Update so it's old enough to be expired when "failed"
    @expired_activity.tasks.last&.update(outcome_status: Task::FAILED, progress_status: Task::COMPLETED)
    @expired_activity.update(
      updated_at: (ExpiredActivityDeleteJob::FAILED_EXPIRATION_DAYS + 1).days.ago
    )

    # Update so it's older than allowed for non-failed activities expiry
    @recent_activity.tasks.last&.update(outcome_status: Task::FAILED, progress_status: Task::COMPLETED)
    @recent_activity.update(
      updated_at: (ExpiredActivityDeleteJob::FAILED_EXPIRATION_DAYS - 1).days.ago
    )

    assert_difference "Activity.count", -1 do
      ExpiredActivityDeleteJob.perform_now
    end

    assert_not Activity.exists?(@expired_activity.id)
    assert Activity.exists?(@recent_activity.id)
  end

  test "deletes expired non-failed activities" do
    # Updates so it's old enough to be expired when "not-failed"
    @expired_activity.update(
      updated_at: (ExpiredActivityDeleteJob::NON_FAILED_EXPIRATION_DAYS + 1).days.ago
    )

    # Update, but it's not expired in any scenario
    @recent_activity.update(
      updated_at: (ExpiredActivityDeleteJob::NON_FAILED_EXPIRATION_DAYS - 1).days.ago
    )

    assert_difference "Activity.count", -1 do
      ExpiredActivityDeleteJob.perform_now
    end

    assert_not Activity.exists?(@expired_activity.id)
    assert Activity.exists?(@recent_activity.id)
  end
end
