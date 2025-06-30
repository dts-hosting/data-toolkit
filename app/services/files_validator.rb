# Given multiple files, validates all supported file types
class FilesValidator
  VALIDATOR_MAP = {
    "text/csv" => CsvValidator
  }.freeze

  def self.call(...) = new(...).call

  # @param files [ActiveStorage::Attachment::Many]
  def initialize(files, feedback = nil)
    @files = files
    @feedback = feedback || Feedback.new("Tasks::ProcessUploadedFiles")
  end

  def call
    begin
      @results = files.map { |file| pick_validator(file).call(file) }
    rescue => err
      @validity_status = false
      Rails.logger.error "#{err.message} -- #{err.backtrace.first(5)}"
      @feedback.add_to_errors(subtype: :application_error, details: err)
    end

    self
  end

  def feedback
    return @feedback if validity_status == false

    @compiled_feedback ||= compile_feedback
  end

  # @return [Boolean, NilClass]
  def valid?
    return false if validity_status == false

    true if feedback.ok?
  end

  def data
    return [] if validity_status == false

    results.map(&:data).compact
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :files, :results, :validity_status

  def pick_validator(file)
    validator = VALIDATOR_MAP[file.blob.content_type]
    validator ||
      raise("Cannot find validator for #{file.filename}")
  end

  def compile_feedback
    results.map(&:feedback)
      .inject(@feedback) do |result, next_value|
        result + next_value
      end
  end
end
