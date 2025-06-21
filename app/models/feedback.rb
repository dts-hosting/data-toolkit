class Feedback
  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  include ActiveModel::Serializers::JSON

  attribute_method_prefix "add_to_"
  define_attribute_methods :errors

  attr_accessor :errors, :warnings, :messages

  def initialize(parent = nil)
    @parent = parent
    @errors = []
    @warnings = []
    @messages = []
  end

  def ok? = errors.empty?

  def displayable? = [errors, warnings, messages].any? { |arr| !arr.empty? }

  # @param [Hash] args
  # @option args [String] :subtype
  # @option args [String, nil] :message
  # @option args [String, nil] :details
  def add_to_attribute(attribute, **args)
    args[:parent] = parent
    args[:type] = attribute.singularize
    send(attribute) << FeedbackElement.new(**args).validate
  end

  def attributes=(hash)
    hash.each do |key, value|
      if key == "parent"
        instance_variable_set(:"@#{key}", value)
      elsif value.blank?
        public_send("#{key}=", value)
      else
        value.each do |element|
          public_send(:"add_to_#{key}", **element.transform_keys(&:to_sym))
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
