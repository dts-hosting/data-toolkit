require "test_helper"

class CsvlintValidatorTest < ActiveSupport::TestCase
  def subject(file)
    CsvlintValidator.call(fixture_file_path(file))
  end

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.valid?
    assert_empty validator.errors
    assert_empty validator.warnings
  end

  test "handles invalid mixed EOL with interspersed blank row CSV" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute validator.valid?
    assert_equal 2, validator.errors.length
    err_classes = validator.errors.map(&:class).uniq
    assert_equal [String], err_classes
  end

  test "handles invalid encoding CSV with no other problems" do
    validator = subject("invalid_encoding.csv")

    refute validator.valid?
    assert_equal 1, validator.errors.length
  end

  test "handles invalid encoding CSV with other problems" do
    validator = subject("invalid_encoding_plus.csv")

    refute validator.valid?
    assert_equal 1, validator.errors.length
  end

  test "returns expected errors for blank rows CSV" do
    validator = subject("blank_rows.csv")

    refute validator.valid?
    assert_equal 1, validator.errors.length
    assert_match(/^Blank Rows:/, validator.errors.first)
  end

  test "warns about single column CSV" do
    validator = subject("single_column.csv")

    assert validator.valid?
    assert_equal 1, validator.warnings.length
    assert_instance_of String, validator.warnings.first
  end

  test "fails if Csvlint validator cannot be created" do
    validator = subject("missing_file.csv")

    refute validator.valid?
    assert_equal 1, validator.errors.length
    assert_empty validator.warnings
  end
end
