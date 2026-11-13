require "test_helper"

class ProcessDeletesActionJobTest < ActiveJob::TestCase
  setup do
    @activity = create_activity(
      type: :delete_records,
      config: {auto_advance: false},
      files: create_uploaded_files(["test.csv"])
    )
    @data_item = DataItem.create!(data: {objectnumber: "123"}, position: 101, activity: @activity)
    @task = @activity.tasks.find_by(type: "process_deletes")
    @action = Action.create!(task: @task, data_item: @data_item)
  end

  test "deletes the record for the data item" do
    ProcessDeletesActionJob.any_instance.expects(:delete).with(@activity, @data_item, anything)

    ProcessDeletesActionJob.perform_now(@activity, @action)

    assert @action.reload.progress_completed?
    assert_nil @action.feedback
  end
end
