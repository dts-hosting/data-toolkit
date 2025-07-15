class IngestDataPreCheckFirstItem
  # @param handler [CollectionSpace::Mapper::SingleRecordType::Handler]
  # @param data [Hash]
  # @param feedback [Feedback]
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

    if empty_header_ct > 0
      empty_header_ct.times do
        feedback_obj.add_to_errors(subtype: :empty_header)
      end
      return self
    end

    unless required_fields_present?
      missing_fields.each do |field|
        feedback_obj.add_to_errors(
          subtype: :required_field_missing, details: field
        )
      end
      return self
    end

    report_known_and_unknown_fields
  end

  def empty_header_ct = @empty_header_ct ||=
                          data.keys.count { |k| k.to_s.blank? }

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
    feedback_obj.add_to_messages(
      subtype: :known_fields,
      details: "#{result[:known_fields].length} of #{field_ct}"
    )
    return if result[:unknown_fields].empty?

    result[:unknown_fields].each do |field|
      feedback_obj.add_to_warnings(
        subtype: :unknown_field,
        details: field
      )
    end
  end
end
