# Given multiple files, validates all supported file types and compiles
#   feedback
class FilesValidator
  VALIDATOR_MAP = {
    "text/csv" => CsvValidator
  }.freeze

  def self.call(...) = new(...).call

  # @param files [ActiveStorage::Attachment::Many]
  def initialize(files)
    @files = files
    @errors = []
  end

  def call
    begin
      @results = files.map { |file| pick_validator(file).call(file) }
    rescue => err
      @validity_status = false
      Rails.logger.error "#{err.message} -- #{err.backtrace.first(5)}"
      @errors << err.message
    end

    self
  end

  # @return [Boolean, NilClass]
  def valid?
    return false if validity_status == false

    true if results.all?(&:valid?)
  end

  # @return [Hash]
  def feedback
    return {errors: errors, warnings: []} unless errors.empty?

    {
      errors: compile_feedback(:errors),
      warnings: compile_feedback(:warnings)
    }
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

  attr_reader :files, :results, :validity_status, :errors

  def pick_validator(file)
    validator = VALIDATOR_MAP[file.blob.content_type]
    validator ||
      raise("Cannot find validator for #{file.filename}")
  end

  def compile_feedback(type)
    results.map do |result|
      next if result.feedback[type].empty?

      {result.feedback[:filename] => result.feedback[type]}
    end.compact
  end
end
