require "test_helper"

class FilesValidatorTest < ActiveSupport::TestCase
  def subject(files) = FilesValidator.call(fixtures_as_attachments(files))

  test "handles missing validator" do
    validator = subject(["test.csv", "not_really_excel.xlsx"])

    refute validator.valid?
    refute_empty validator.feedback[:errors]
    assert_equal "Cannot find validator for not_really_excel.xlsx",
      validator.feedback[:errors].first
    assert_empty validator.feedback[:warnings]
    assert_empty validator.data
  end

  test "handles multiple valid CSVs" do
    validator = subject(["single_column.csv", "valid_lf.csv"])

    assert validator.valid?
    assert_empty validator.feedback[:errors]
    assert_equal 1, validator.feedback[:warnings].length
    assert_equal 2, validator.data.length
  end

  test "handles valid and invalid CSVs" do
    validator = subject(["test.csv", "invalid_encoding.csv"])

    refute validator.valid?
    assert_equal 1, validator.feedback[:errors].length
    err = {"invalid_encoding.csv" =>
     ["Invalid Encoding: Invalid UTF-8 encoding in row 2",
       "Invalid byte sequence in UTF-8 in line 2."]}
    assert_equal err, validator.feedback[:errors].first
    assert_equal 1, validator.data.length
  end

  test "handles multiple invalid CSVs" do
    validator = subject(["invalid_mixed_eol_blank_middle_row.csv",
      "invalid_encoding.csv"])

    refute validator.valid?
    assert_equal 2, validator.feedback[:errors].length
    assert_empty validator.data
  end
end
