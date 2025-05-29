# frozen_string_literal: true

# Abstract class for FeedbackError, FeedbackWarning, and FeedbackMessage
#  to inherit from
class FeedbackElement
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_reader :category, :message, :detail

  # @param parent [String] class name of the instance whose Feedback this
  #   element belongs to
  def initialize(parent:, category:, message: nil, detail: nil)
    @parent = parent
    @category = category
    @message = message
    @detail = detail
    @general_categories = get_general_categories
    @msgs = get_msgs
  end

  def validate
    unless known_category?
      raise StandardError,
        "Unknown #{self.class} category for #{parent}: #{category}"
    end

    unless has_message?
      raise StandardError,
        "No #{self.class} message given or configured for " \
        "#{parent}: #{category}"
    end

    self
  end

  def attributes
    {"category" => category, "message" => message, "detail" => detail}
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} " \
      "category: #{category}> " \
      "message: #{message} " \
      "detail: #{detail}"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :parent, :general_categories, :msgs

  def get_general_categories
    if self.class.const_defined?(:GENERAL_CATEGORIES)
      return self.class.const_get(:GENERAL_CATEGORIES)
    end

    []
  end

  def get_msgs
    return self.class.const_get(:MSGS) if self.class.const_defined?(:MSGS)

    {}
  end

  def known_category?
    return true if general_categories.include?(category)

    msgs[parent].key?(category)
  end

  def has_message?
    true if message || msgs.dig(parent, category)
  end
end
