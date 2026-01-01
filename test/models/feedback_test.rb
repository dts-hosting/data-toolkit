class FeedbackTest < ActiveSupport::TestCase
  test "doesn't return display stuff when non-displayable" do
    f = Feedback.new("Tasks::PreCheckIngestData")
    assert f.ok?
    assert_empty f.for_display
    refute f.displayable?
  end

  test "compiles messages and warnings as expected" do
    f = Feedback.new("Tasks::PreCheckIngestData")
    f.add_to_messages(
      subtype: :known_fields,
      details: "5 of 7"
    )
    f.add_to_warnings(
      subtype: :unknown_field,
      details: :foo
    )
    f.add_to_warnings(
      subtype: :unknown_field,
      details: :bar
    )
    assert f.ok?
    assert f.displayable?
    expected = {
      warnings: ["2 fields will <b>not</b> import: foo; bar"],
      messages: ["5 of 7 fields will import"]
    }
    assert_equal expected, f.for_display
  end

  test "compiles application error as expected" do
    f = Feedback.new("Tasks::PreCheckIngestData")
    f.add_to_errors(
      subtype: :application_error,
      details: "blah"
    )
    refute f.ok?
    assert f.displayable?
    result = f.for_display[:errors].first
    assert_match(/^Application has failed for an unexpected reason/, result)
    assert_match(/ERROR RECEIVED: blah$/, result)
  end
end
