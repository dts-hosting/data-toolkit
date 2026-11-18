require "test_helper"

class PrepareTransfersActionJobTest < ActiveJob::TestCase
  setup do
    @activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      files: create_uploaded_files(["test.csv"])
    )
    @data_item = DataItem.create!(data: {objectnumber: "123"}, position: 101, activity: @activity)
    @task = @activity.tasks.find_by(type: "prepare_transfers")
    @action = Action.create!(task: @task, data_item: @data_item)
    CollectionSpaceMapper.stubs(:single_record_type_handler_for).returns(Object.new)
  end

  test "attaches the generated xml as the data item payload" do
    xml = "<document><objectNumber>123</objectNumber></document>"
    PrepareTransfersActionJob.any_instance.stubs(:generate_xml).returns(xml)

    PrepareTransfersActionJob.perform_now(@activity, @action)

    assert @action.reload.progress_completed?
    assert_nil @action.feedback
    assert @data_item.reload.payload.attached?
    assert_equal xml, @data_item.payload.download
    assert_equal "application/xml", @data_item.payload.content_type
  end

  test "does not attach a payload when xml generation adds errors" do
    PrepareTransfersActionJob.perform_now(@activity, @action)

    assert @action.reload.progress_completed?
    assert @action.feedback_for.errors.any?
    refute @data_item.reload.payload.attached?
  end
end
