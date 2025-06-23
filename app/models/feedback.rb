class Feedback
  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  include ActiveModel::Serializers::JSON

  attribute_method_prefix "add_to_"
  attribute_method_prefix "clear_"
  # define_attribute_methods :errors

  attr_accessor :errors, :warnings, :messages

  # @param parent [String] name of Task with which Feedback is associated
  def initialize(parent = nil)
    @parent = parent
    @errors = []
    @warnings = []
    @messages = []
  end

  def ok? = errors.empty?

  def displayable? = [errors, warnings, messages].any? { |arr| !arr.empty? }

  def +(other)
    @errors = [errors, other.errors].flatten
    @warnings = [warnings, other.warnings].flatten
    @messages = [messages, other.messages].flatten
    self
  end

  def for_display
    return {} unless displayable?

    %i[errors warnings messages].map do |type|
      msgs = compile_display_messages(type)
      next unless msgs

      [type, msgs]
    end
      .compact
      .to_h
  end

  # @param [Hash] args
  # @option args [String] :subtype
  # @option args [String, nil] :message
  # @option args [String, nil] :details
  def add_to_attribute(attribute, **args)
    args[:parent] = parent
    args[:type] = attribute.singularize
    send(attribute) << FeedbackElement.new(**args).validate
  end

  def clear_attribute(attribute)
    instance_variable_set(:"@#{attribute}", [])
  end

  def attributes=(hash)
    hash.each do |key, value|
      if key == "parent"
        instance_variable_set(:"@#{key}", value)
      elsif value.blank?
        public_send("#{key}=", value)
      else
        value.each do |element|
          h = element.transform_keys(&:to_sym)
          public_send(:"add_to_#{key}", **h)
        end
      end
    end
  end

  def attributes
    {"parent" => parent, "errors" => [], "warnings" => [], "messages" => []}
  end

  private

  attr_reader :parent

  def compile_display_messages(type)
    elements = send(type)
    return if elements.empty?

    elements.group_by(&:subtype)
      .map { |subtype, elements| subtype_message(subtype, elements) }
  end

  def subtype_message(subtype, elements)
    path = elements.first.msg_lookup_path
    details = elements.map(&:details)
      .compact
      .uniq
      .join("; ")
    params = {count: elements.count, details: details}
    I18n.t(path, **params)
  end
end
