class CsvValidator
  DEFAULT_DIALECT = {header: true, delimiter: ","}.freeze

  # @param file [ActiveStorage::Attachment]
  # @param taskname [String] feedback context for task
  # @param dialect [Hash]
  def initialize(file:, taskname:, dialect: DEFAULT_DIALECT)
    @file = file
    @taskname = taskname
    @dialect = dialect
  end

  def call
    @filename = file.filename.to_s
    file.open do |f|
      path = Pathname.new(f.path)
      @csvlint = CsvlintValidator.new(
        filepath: path,
        taskname: taskname,
        filename: filename,
        dialect: dialect
      ).call
      @stdlib = CsvStdlibValidator.new(
        filepath: path,
        taskname: taskname,
        filename: filename
      ).call
    end

    self
  end

  def feedback = @feedback ||= compile_feedback

  def valid? = feedback.ok?

  def data = stdlib.data

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} filename: #{filename} " \
      "valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :file, :taskname, :dialect, :filename, :filepath, :csvlint, :stdlib

  def blank_row_failure?
    csvlint.feedback.errors.map(&:subtype) == [:csvlint_blank_rows]
  end

  def compile_feedback
    if blank_row_failure?
      csvlint.feedback.clear_errors
    end

    csvlint.feedback + stdlib.feedback
  end
end
