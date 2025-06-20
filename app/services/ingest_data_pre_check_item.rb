class IngestDataPreCheckItem
  def initialize(handler, data, feedback)
    @handler = handler
    @data = data
    @feedback_obj = feedback
    @status = :not_checked
  end

  def ok?
    run_checks unless @status == :checked

    feedback_obj.ok?
  end

  def feedback
    run_checks unless @status == :checked

    feedback_obj
  end

  private

  attr_reader :handler, :data, :feedback_obj

  def run_checks
    @status = :checked

    if empty_required_fields?
      feedback_obj.add_to_errors(
        subtype: :required_field_value_missing,
        details: empty_fields.join("; ")
      )
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
