require "minitest/mock"
require "ostruct"
require "test_helper"

class IngestDataPreCheckFirstItemTest < ActiveJob::TestCase
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

  test "fails when there is a blank header" do
    @data_hash = {objectnumber: "1", title: "t", "": "foo"}
    checker = IngestDataPreCheckFirstItem.new(@mock_handler, @data_hash)
    feedback = {
      messages: {},
      warnings: {},
      errors: {"One or more headers in spreadsheet are empty" => []}
    }
    assert_equal feedback, checker.feedback
    refute checker.ok?
  end

  test "fails when required field is missing" do
    @data_hash = {title: "t", briefdescription: "foo"}
    @mock_handler.expect(:validate, missing_required_field_response,
      [@data_hash])
    checker = IngestDataPreCheckFirstItem.new(@mock_handler, @data_hash)
    feedback = {
      messages: {},
      warnings: {},
      errors: {"Required field(s) missing" => %w[objectnumber fakerequired]}
    }
    assert_equal feedback, checker.feedback
    refute checker.ok?
  end

  test "reports known and unknown fields" do
    @data_hash = {objectnumber: "1", title: "t", briefdescription: "foo",
                  random: "unknown", blah: "unknown"}
    @mock_handler.expect(:validate, valid_response, [@data_hash])
    @mock_handler.expect(:check_fields,
      {known_fields: %i[objectnumber title briefdescription],
       unknown_fields: %i[random blah]},
      [@data_hash])
    checker = IngestDataPreCheckFirstItem.new(@mock_handler, @data_hash)
    feedback = {
      messages: {"Fields that will import" => ["3 of 5"]},
      warnings: {"2 field(s) will not import" => %i[random blah]},
      errors: {}
    }
    assert_equal feedback, checker.feedback
    assert checker.ok?
  end

  private

  def missing_required_field_response = OpenStruct.new(
    valid?: false,
    errors: ["required field missing: objectnumber must be present",
      "required field missing: fakerequired must be present"]
  )

  def valid_response = OpenStruct.new(valid?: true)
end
