class IngestDataPreCheckItem
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

    if empty_required_fields?
      @errors["Empty required field(s)"] = empty_fields
    end
  end

  def empty_required_fields? = !empty_required_fields.empty?

  def empty_required_fields
    @empty_required_fields ||= validated.errors.select do |err|
      err.start_with?("required field empty")
    end
  end

  def empty_fields = empty_required_fields.map do |err|
    err.split(": ").last
  end

  def validated = @validated ||= handler.validate(data)
end
