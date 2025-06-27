require "test_helper"

class CsvStdlibValidatorTest < ActiveSupport::TestCase
  def subject(file)
    CsvStdlibValidator.call(fixture_file_path(file))
  end

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.feedback.ok?
    assert_empty validator.feedback.errors
    assert_empty validator.feedback.warnings
    assert_instance_of CSV::Table, validator.data
  end

  test "handles invalid CSV" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute validator.feedback.ok?
    assert_equal [:csv_stdlib_malformed_csv],
      validator.feedback.errors.map(&:subtype)
    assert_empty validator.feedback.warnings
    assert_nil validator.data
  end
end
