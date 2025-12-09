require "minitest/mock"
require "ostruct"
require "test_helper"

class IngestDataPreCheckFirstItemTest < ActiveJob::TestCase
  setup do
    activity = create_activity
    @task = activity.tasks.create(type: :pre_check_ingest_data)
    @data_item = DataItem.new(
      data: @data_hash,
      position: 0,
      activity: activity
    )
    @mock_handler = Minitest::Mock.new
    @feedback = Feedback.new(@task.feedback_context)
  end

  test "fails when there is a blank header" do
    @data_hash = {objectnumber: "1", title: "t", "": "foo"}
    checker = IngestDataPreCheckFirstItem.new(
      @mock_handler, @data_hash, @feedback
    )
    assert_empty checker.feedback.messages
    assert_empty checker.feedback.warnings
    assert_equal 1, checker.feedback.errors.length
    assert_equal :empty_header, checker.feedback.errors.first.subtype
    refute checker.ok?
  end

  test "fails when required field is missing" do
    @data_hash = {title: "t", briefdescription: "foo"}
    @mock_handler.expect(:validate, missing_required_field_response,
      [@data_hash])
    checker = IngestDataPreCheckFirstItem.new(
      @mock_handler, @data_hash, @feedback
    )
    assert_empty checker.feedback.messages
    assert_empty checker.feedback.warnings
    assert_equal 2, checker.feedback.errors.length
    assert_equal %i[required_field_missing required_field_missing],
      checker.feedback.errors.map(&:subtype)
    assert_equal %w[objectnumber fakerequired],
      checker.feedback.errors.map(&:details)
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
    checker = IngestDataPreCheckFirstItem.new(
      @mock_handler, @data_hash, @feedback
    )
    assert_empty checker.feedback.errors
    assert_equal 1, checker.feedback.messages.length
    assert_equal [:known_fields],
      checker.feedback.messages.map(&:subtype)
    assert_equal 2, checker.feedback.warnings.length
    assert_equal [:unknown_field],
      checker.feedback.warnings.map(&:subtype).uniq
    assert_equal %i[random blah],
      checker.feedback.warnings.map(&:details)
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
