require "minitest/mock"
require "ostruct"
require "test_helper"

class IngestDataPreCheckItemTest < ActiveJob::TestCase
  setup do
    activity = create_activity
    @task = activity.tasks.create(type: :pre_check_ingest_data)
    @data_item = DataItem.new(
      data: {},
      position: 0,
      activity: activity
    )
    @mock_handler = Minitest::Mock.new
  end

  test "fails when required field is empty" do
    data_hash = {objectnumber: "", title: "t", "": "foo"}
    @data_item.update!(data: data_hash)
    @action = Action.create!(task: @task, data_item: @data_item)
    @action.start!

    @mock_handler.expect(:validate, empty_required_field_response,
      [data_hash])
    checker = IngestDataPreCheckItem.new(
      @mock_handler, data_hash, @action.feedback_for
    )

    assert_equal [:required_field_value_missing],
      checker.feedback.errors.map(&:subtype)
    assert_equal ["objectnumber must be populated"],
      checker.feedback.errors.map(&:details)
    refute checker.ok?
  end

  test "succeeds when data is valid" do
    data_hash = {objectnumber: "123", title: "t", "": "foo"}
    @data_item.update!(data: data_hash)
    @action = Action.create!(task: @task, data_item: @data_item)
    @action.start!

    @mock_handler.expect(:validate, valid_response,
      [data_hash])
    checker = IngestDataPreCheckItem.new(
      @mock_handler, data_hash, @action.feedback_for
    )
    refute checker.feedback.displayable?
    assert checker.ok?
  end

  private

  def empty_required_field_response = OpenStruct.new(
    valid?: false,
    errors: ["required field empty: objectnumber must be populated"]
  )

  def valid_response = OpenStruct.new(valid?: true, errors: [])
end
