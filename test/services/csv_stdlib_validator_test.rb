require "test_helper"

class CsvStdlibValidatorTest < ActiveSupport::TestCase
  def subject(file)
    CsvStdlibValidator.call(fixture_file_path(file))
  end

  test "handles valid CSV" do
    validator = subject("valid_lf.csv")

    assert validator.valid?
    assert_empty validator.errors
    assert_empty validator.warnings
    assert_instance_of CSV::Table, validator.data
  end

  test "handles invalid CSV" do
    validator = subject("invalid_mixed_eol_blank_middle_row.csv")

    refute validator.valid?
    assert_equal 1, validator.errors.length
    assert_instance_of String, validator.errors.first
    assert_empty validator.warnings
    assert_nil validator.data
  end
end
