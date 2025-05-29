require "test_helper"

class CsvlintValidatorTest < ActiveSupport::TestCase
  def subject(file)
    CsvlintValidator.call(fixture_file_path(file)).feedback
  end

  test "handles valid CSV" do
    feedback = subject("valid_lf.csv")

    assert feedback.ok?
    assert_empty feedback.errors
    assert_empty feedback.warnings
  end

  test "handles invalid mixed EOL with interspersed blank row CSV" do
    feedback = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute feedback.ok?
    assert_equal %i[csvlint_unknown_error csvlint_line_breaks],
      feedback.errors.map(&:subtype)
  end

  test "handles invalid encoding CSV with no other problems" do
    feedback = subject("invalid_encoding.csv")

    refute feedback.ok?
    assert_equal [:csvlint_invalid_encoding], feedback.errors.map(&:subtype)
  end

  test "handles invalid encoding CSV with other problems" do
    feedback = subject("invalid_encoding_plus.csv")

    refute feedback.ok?
    assert_equal [:csvlint_invalid_encoding], feedback.errors.map(&:subtype)
  end

  test "returns expected errors for blank rows CSV" do
    feedback = subject("blank_rows.csv")

    refute feedback.ok?
    assert_equal [:csvlint_blank_rows], feedback.errors.map(&:subtype)
  end

  test "warns about single column CSV" do
    feedback = subject("single_column.csv")

    assert feedback.ok?
    assert_equal %i[csvlint_check_options csvlint_check_options],
      feedback.warnings.map(&:subtype)
  end

  test "doesn't warn about title row CSV" do
    feedback = subject("title_row.csv")

    assert feedback.ok?
    assert_empty feedback.warnings
  end

  test "fails if Csvlint feedback cannot be created" do
    feedback = subject("missing_file.csv")

    refute feedback.ok?
    assert_equal 1, feedback.errors.length
  end
end
