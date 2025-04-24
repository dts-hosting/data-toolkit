class IngestDataPreCheckFirstItem
  def initialize(handler, data)
    @handler = handler
    @data = data
    @messages = {}
    @warnings = {}
    @errors = {}
    @status = :not_checked
  end

  def ok?
    run_checks unless @status == :checked

    @errors.empty?
  end

  def feedback
    run_checks unless @status == :checked

    {messages: @messages, warnings: @warnings, errors: @errors}
  end

  private

  attr_reader :handler, :data

  def run_checks
    @status = :checked

    if empty_headers?
      @errors["One or more headers in spreadsheet are empty"] = []
      return self
    end

    unless required_fields_present?
      @errors["Required field(s) missing"] = missing_fields
      return self
    end

    report_known_and_unknown_fields
  end

  def empty_headers? = data.keys.any? { |k| k.to_s.blank? }

  def validated = @validated ||= handler.validate(data)

  def missing_field_errors
    @missing_field_errors ||= validated.errors.select do |err|
      err.start_with?("required field missing: ")
    end
  end

  def required_fields_present?
    true if validated.valid? || missing_field_errors.empty?
  end

  def missing_fields = missing_field_errors.map do |err|
    err.split(": ")
      .last
      .delete_suffix(" must be present")
  end

  def field_ct = @field_ct ||= data.keys.length

  def report_known_and_unknown_fields
    result = handler.check_fields(data)
    @messages["Fields that will import"] =
      ["#{result[:known_fields].length} of #{field_ct}"]
    return if result[:unknown_fields].empty?

    @warnings["#{result[:unknown_fields].length} field(s) will not import"] =
      result[:unknown_fields]
  end
end
