require "test_helper"

class ProcessTransfersActionJobTest < ActiveJob::TestCase
  setup do
    @activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      files: create_uploaded_files(["test.csv"])
    )
    @data_item = DataItem.create!(data: {objectnumber: "123"}, position: 101, activity: @activity)
    @task = @activity.tasks.find_by(type: "process_transfers")
    @action = Action.create!(task: @task, data_item: @data_item)
  end

  test "transfers the data item when it has a payload" do
    @data_item.payload.attach(io: StringIO.new("<document/>"), filename: "item.xml", content_type: "application/xml")
    ProcessTransfersActionJob.any_instance.expects(:transfer)
      .with(@activity, @data_item, anything)

    ProcessTransfersActionJob.perform_now(@activity, @action)

    assert @action.reload.progress_completed?
    assert_nil @action.feedback
  end

  test "adds an error when the data item has no payload" do
    ProcessTransfersActionJob.any_instance.expects(:transfer).never

    ProcessTransfersActionJob.perform_now(@activity, @action)

    assert @action.reload.progress_completed?
    assert_equal ["payload_missing"], @action.feedback_for.errors.map { |e| e.subtype.to_s }
  end
end
