class CsvValidator
  DEFAULT_DIALECT = {header: true, delimiter: ","}.freeze

  def self.call(...) = new(...).call

  # @param file [ActiveStorage::Attachment]
  # @param dialect [Hash]
  def initialize(file, dialect: DEFAULT_DIALECT)
    @file = file
    @dialect = dialect
  end

  def call
    @filename = file.filename.to_s
    file.open do |f|
      @csvlint = CsvlintValidator.call(f.path, dialect: dialect)
      @stdlib = CsvStdlibValidator.call(f.path)
    end
    self
  end

  # @return [Boolean, NilClass]
  def valid?
    return true if blank_row_failure? && stdlib.valid?

    csvlint.valid?
  end

  # @return [Hash]
  def feedback = {
    filename: filename,
    errors: errors,
    warnings: csvlint.warnings
  }

  def errors
    return [] if valid?

    [csvlint.errors, stdlib.errors].flatten
  end

  def data = stdlib.data

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} filename: #{filename} " \
      "valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :file, :dialect, :filename, :filepath, :csvlint, :stdlib

  def blank_row_failure?
    csvlint.errors.length == 1 &&
      csvlint.errors.first.match?(/^Blank Rows: /)
  end
end
