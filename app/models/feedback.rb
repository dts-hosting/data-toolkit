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
end
