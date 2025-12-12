class CsvValidatorTest < ActiveSupport::TestCase
  def subject(file) = CsvValidator.new(
    file: fixtures_as_attachments([file]).first,
    taskname: "Tasks::ProcessUploadedFiles"
  ).call

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.valid?
    assert_empty validator.feedback.errors
  end

  test "handles invalid CSV" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute validator.valid?
    assert_equal %i[csvlint_unknown_error
      csvlint_line_breaks
      csv_stdlib_malformed_csv],
      validator.feedback.errors.map(&:subtype)
    assert_equal "invalid_mixed_eol_blank_middle_row.csv",
      validator.feedback.errors.first.prefix
  end

  test "handles CSV that fails csvlint due to blank rows, but is parseable" do
    validator = subject("blank_rows.csv")

    assert validator.valid?
    assert_empty validator.feedback.errors
  end
end
