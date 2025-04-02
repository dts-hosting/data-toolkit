require "csvlint"

# Wrapper around Csvlint validation
class CsvlintValidator
  ERR_STRINGS = {
    assumed_header: nil,
    blank_rows:
    "Blank Rows: All column values in row ROW are empty",
    check_options:
    "Single Column: Ok if you are expecting only one column of data; " \
      "Problem with CSV format if you are expecting more than one column",
    duplicate_column_name:
    "Duplicate Headers: Column headers should be unique",
    encoding: nil,
    empty_column_name:
    "Column Without Header: Data from column COLUMN will not be " \
      "processed",
    excel: nil,
    inconsistent_values:
    "Inconsistent Values: You may wish to double check the values in " \
      "column COLUMN",
    invalid_encoding:
    "Invalid Encoding: Invalid UTF-8 encoding in row ROW",
    line_breaks:
    "Line Breaks: Different styles of end-of-line characters used in file",
    no_content_type: nil,
    no_encoding: nil,
    nonrfc_line_breaks: nil,
    not_found: nil,
    ragged_rows:
    "Ragged Rows: Row ROW has a different number of columns than " \
      "the first row in the file",
    stray_quote:
    "Stray Quote: Missing or stray quote in row ROW",
    title_row: nil,
    unclosed_quote:
    "Unclosed Quote: Unclosed quoted field in row ROW",
    unknown_error:
    "Unknown Error: Things to check for include: different styles of " \
      "end-of-line characters used AND blank row(s) present in data",
    whitespace:
    "Whitespace: A quoted column in ROW has leading or trailing " \
      "whitespace",
    wrong_content_type: nil
  }.freeze

  def self.call(...) = new(...).call

  # @param filepath [String]
  # @param dialect [Hash]
  def initialize(filepath, dialect: CsvValidator::DEFAULT_DIALECT)
    @filepath = filepath
    @dialect = dialect
    @errors = []
  end

  # @return [CsvlintValidator]
  def call
    get_validator
    return self if validator == :failure

    validator.validate
    self
  end

  # @return [Boolean]
  def valid?
    return false if validator == :failure

    validator.valid?
  end

  # @return [Array<String>]
  def errors
    return @errors if validator == :failure || valid?

    # Invalid encoding can cause a cascade of other errors to be reported
    #   at the same time, and people don't notice or don't know to address
    #   the encoding issue(s) first. For this reason, if :invalid_encoding
    #   is one of the errors, we ONLY return that one, in the hopes that
    #   fixing the encoding fixes the file.
    encoding_err = validator.errors
      .select { |err| err.type == :invalid_encoding }
    return stringify_errors(validator.errors) if encoding_err.empty?

    stringify_errors(encoding_err)
  end

  # @return [Array<String>]
  def warnings
    return [] unless valid?

    stringify_errors(validator.warnings)
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :filepath, :dialect, :validator

  def get_validator
    @validator = Csvlint::Validator.new(File.new(filepath), dialect)
  rescue => err
    Rails.logger.error "#{filepath} - #{err.message}\n#{err.backtrace}"
    @errors << err.message
    @validator = :failure
  end

  # @param errs [Array<Csvlint::ErrorMessage>]
  # @return [Array<String>]
  def stringify_errors(errs) = errs.map { |err| stringify_error(err) }
    .compact
    .uniq

  # @param errs [Csvlint::ErrorMessage]
  # @return [String]
  def stringify_error(err)
    return err.type unless ERR_STRINGS.key?(err.type)

    message = ERR_STRINGS[err.type]
    return message if message.nil?

    column = err.column.to_s || ""
    row = err.row.to_s || ""
    with_col = message.sub("COLUMN", column)
    with_col.sub("ROW", row)
  end
end
