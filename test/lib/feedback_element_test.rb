require "test_helper"
require "webmock/minitest"

class FeedbackElementTest < ActiveSupport::TestCase
  test "Unknown subtype does not validate" do
    err = FeedbackElement.new(
      parent: "Tasks::PreCheckIngestData",
      type: :error,
      subtype: "foo"
    )
    assert_raises(
      StandardError,
      "Unknown error subtype for Tasks::PreCheckIngestData: foo"
    ) { err.validate }
  end

  test "Returns pluralized messages as expected" do
    FeedbackElement.new(
      parent: "Tasks::PreCheckIngestData",
      type: :error,
      subtype: "required field missing"
    )
  end
end
