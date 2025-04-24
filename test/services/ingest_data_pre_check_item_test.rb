require "minitest/mock"
require "ostruct"
require "test_helper"

class IngestDataPreCheckItemTest < ActiveJob::TestCase
  setup do
    activity = create_activity
    task = activity.tasks.create(type: "Tasks::PreCheckIngestData")
    @data_item = DataItem.new(
      data: @data_hash,
      position: 0,
      activity: activity,
      current_task_id: task.id
    )
    @mock_handler = Minitest::Mock.new
  end

  test "fails when required field is empty" do
    @data_hash = {objectnumber: "", title: "t", "": "foo"}
    @mock_handler.expect(:validate, empty_required_field_response,
      [@data_hash])
    checker = IngestDataPreCheckItem.new(@mock_handler, @data_hash)
    feedback = {
      messages: {},
      warnings: {},
      errors: {"Empty required field(s)" => ["objectnumber must be populated"]}
    }
    assert_equal feedback, checker.feedback
    refute checker.ok?
  end

  test "succeeds when data is valid" do
    @data_hash = {objectnumber: "123", title: "t", "": "foo"}
    @mock_handler.expect(:validate, valid_response,
      [@data_hash])
    checker = IngestDataPreCheckItem.new(@mock_handler, @data_hash)
    feedback = {
      messages: {},
      warnings: {},
      errors: {}
    }
    assert_equal feedback, checker.feedback
    assert checker.ok?
  end

  private

  def empty_required_field_response = OpenStruct.new(
    valid?: false,
    errors: ["required field empty: objectnumber must be populated"]
  )

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
