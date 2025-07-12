require "test_helper"

class FilesValidatorTest < ActiveSupport::TestCase
  def subject(files) = FilesValidator.new(
    files: fixtures_as_attachments(files),
    taskname: "Tasks::ProcessUploadedFiles"
  ).call

  test "handles missing validator" do
    validator = subject(["test.csv", "not_really_excel.xlsx"])

    refute validator.valid?
    assert_includes validator.feedback.errors.first.details,
      "Cannot find validator for not_really_excel.xlsx"
    assert_empty validator.feedback.warnings
    assert_empty validator.data
  end

  test "handles multiple valid CSVs" do
    validator = subject(["single_column.csv", "valid_lf.csv"])

    assert validator.valid?
    assert_empty validator.feedback.errors
    assert_equal [:csvlint_check_options],
      validator.feedback.warnings.map(&:subtype).uniq
    assert_equal 2, validator.data.length
  end

  test "handles valid and invalid CSVs" do
    validator = subject(["test.csv", "invalid_encoding.csv"])

    refute validator.valid?
    feedback = validator.feedback
    assert_equal %i[csvlint_invalid_encoding csv_stdlib_malformed_csv],
      feedback.errors.map(&:subtype)
    assert_equal ["invalid_encoding.csv"],
      feedback.errors.map(&:prefix).uniq
    assert_equal 1, validator.data.length
  end

  test "handles multiple invalid CSVs" do
    validator = subject(["invalid_mixed_eol_blank_middle_row.csv",
      "invalid_encoding.csv"])

    refute validator.valid?
    assert_equal ["invalid_encoding.csv",
      "invalid_mixed_eol_blank_middle_row.csv"],
      validator.feedback.errors.map(&:prefix).uniq.sort
    assert_empty validator.data
  end
end
