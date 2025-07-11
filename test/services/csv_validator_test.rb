require "test_helper"

class CsvValidatorTest < ActiveSupport::TestCase
  def subject(file) = CsvValidator.call(
    fixtures_as_attachments([file]).first
  )

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.valid?
    assert_empty validator.feedback[:errors]
  end

  test "handles invalid CSV" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute validator.valid?
    assert_equal 3, validator.feedback[:errors].length
  end

  test "handles CSV that fails csvlint due to blank rows, but is parseable" do
    validator = subject("blank_rows.csv")

    assert validator.valid?
    assert_empty validator.feedback[:errors]
  end
end
