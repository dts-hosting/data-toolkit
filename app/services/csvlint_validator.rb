require "csvlint"

# Wrapper around Csvlint validation
class CsvlintValidator
  attr_reader :feedback

  # @param filepath [String]
  # @param taskname [String] feedback context for task
  # @param filename [nil, String] the user-known filename is not the basename
  #   of the Rails storage path, so this should be passed explicitly in
  #   production, so the feedback can record which file it is about
  # @param dialect [Hash]
  def initialize(filepath:, taskname:, filename: nil,
    dialect: CsvValidator::DEFAULT_DIALECT)
    @filepath = filepath
    @filename = filename || filepath.basename.to_s
    @dialect = dialect
    @feedback = Feedback.new(taskname)
    @feedback_subtype_prefix = :csvlint
  end

  # @return [CsvlintValidator]
  def call
    get_validator
    return self if validator == :failure

    validate
    self
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} " \
      "filename: #{filename} " \
      "valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :filepath, :filename, :dialect, :validator,
    :feedback_subtype_prefix

  def get_validator
    @validator = Csvlint::Validator.new(File.new(filepath), dialect)
  rescue => err
    Rails.logger.error "#{filepath} - #{err.message}\n#{err.backtrace}"
    feedback.add_to_errors(subtype: :application_error, details: err,
      prefix: filename)
    @validator = :failure
  end

  def validate
    validator.validate
    populate_feedback
  end

  def populate_feedback
    # Invalid encoding can cause a cascade of other errors to be reported
    #   at the same time, and people don't notice or don't know to address
    #   the encoding issue(s) first. For this reason, if :invalid_encoding
    #   is one of the errors, we ONLY return that one, in the hopes that
    #   fixing the encoding fixes the other issues reported for the file.
    errs = validator.errors
    encoding_err = errs.find { |err| err.type == :invalid_encoding }
    add_feedback(encoding_err, type: :error) && return if encoding_err

    errs.each { |err| add_feedback(err, type: :error) }
    validator.warnings.each { |wrn| add_feedback(wrn, type: :warning) }
  end

  def add_feedback(item, type:)
    params = {
      subtype: :"#{feedback_subtype_prefix}_#{item.type}",
      details: compile_details(item),
      prefix: filename
    }
    meth = :"add_to_#{type}s"
    feedback.send(meth, **params)
  rescue FeedbackSubtypeError
    # Ignore csvlint error/warning types we haven't defined messages for
  end

  def compile_details(item)
    return if !item.row && !item.column

    %i[row column].map do |axis|
      result = item.send(axis)
      next unless result

      "#{axis} #{result}"
    end.compact
      .join(", ")
  end
end
