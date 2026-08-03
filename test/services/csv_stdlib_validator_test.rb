class CsvStdlibValidatorTest < ActiveSupport::TestCase
  def subject(file)
    CsvStdlibValidator.new(
      filepath: fixture_file_path(file),
      taskname: "Tasks::ProcessUploadedFiles"
    ).call
  end

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.feedback.ok?
    assert_empty validator.feedback.errors
    assert_empty validator.feedback.warnings
    assert_instance_of CSV::Table, validator.data
  end

  test "handles invalid CSV" do
    validator = subject("malformed_quotes.csv")

    refute validator.feedback.ok?
    assert_equal [:csv_stdlib_malformed_csv],
      validator.feedback.errors.map(&:subtype)
    assert_empty validator.feedback.warnings
    assert_nil validator.data
  end

  # As of csv 3.3.6: https://github.com/ruby/csv/pull/346
  test "parses mixed EOL CSV rejected by csvlint" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    assert validator.feedback.ok?
    assert_instance_of CSV::Table, validator.data
  end
end
