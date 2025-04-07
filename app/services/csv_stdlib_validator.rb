require "csv"

# Checks whether Ruby CSV standard library can parse the file without
#   falling over. This is necessary because Csvlint sometimes fails files
#   that Ruby can handle with no problem.
class CsvStdlibValidator
  def self.call(...) = new(...).call

  # @return [Array<String>]
  attr_reader :errors

  # @return [CSV::Table]
  attr_reader :data

  # @param filepath [String]
  def initialize(filepath)
    @filepath = filepath
    @errors = []
  end

  # @return [CsvStdlibValidator]
  def call
    run_validation
    self
  end

  # @return [Boolean, NilClass]
  def valid? = validity_status

  # To provide consistent interface
  def warnings = []

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :filepath, :validity_status

  def run_validation
    @data = File.open(filepath, encoding: "bom|utf-8") do |file|
      CSV.table(file)
    end
    @validity_status = true
  rescue CSV::MalformedCSVError => err
    Rails.logger.error "#{filepath} - #{err.message}\n#{err.backtrace}"
    errors << err.message
    @validity_status = false
  end
end
