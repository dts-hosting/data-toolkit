require "csv"

# Checks whether Ruby CSV standard library can parse the file without
#   falling over. This is necessary because Csvlint sometimes fails files
#   that Ruby can handle with no problem.
class CsvStdlibValidator
  # @return [CSV::Table]
  attr_reader :data

  # @return [Feedback]
  attr_reader :feedback

  # @param filepath [String]
  # @param taskname [String] feedback context for task
  # @param filename [nil, String] the user-known filename is not the basename
  #   of the Rails storage path, so this should be passed explicitly in
  #   production, so the feedback can record which file it is about
  def initialize(filepath:, taskname:, filename: nil)
    @filepath = filepath
    @filename = filename || filepath.basename.to_s
    @feedback = Feedback.new(taskname)
    @feedback_subtype_prefix = :csv_stdlib
  end

  # @return [CsvStdlibValidator]
  def call
    run_validation
    self
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} " \
      "filename: #{filename} " \
      "valid?: #{valid?}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :filepath, :filename, :feedback_subtype_prefix

  def run_validation
    @data = File.open(filepath, encoding: "bom|utf-8") do |file|
      CSV.table(file)
    end
  rescue CSV::MalformedCSVError => err
    Rails.logger.error "#{filepath} - #{err.message}\n#{err.backtrace}"
    feedback.add_to_errors(subtype: :"#{feedback_subtype_prefix}_malformed_csv",
      details: err.message,
      prefix: filename)
  end
end
