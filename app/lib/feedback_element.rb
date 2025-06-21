# frozen_string_literal: true

# Abstract class for FeedbackError, FeedbackWarning, and FeedbackMessage
#  to inherit from
class FeedbackElement
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_reader :subtype, :message, :details

  # @param parent [String] class name of the instance whose Feedback this
  #   element belongs to
  # @param type [:error, :warning, :message]
  # @param subtype [Symbol]
  def initialize(parent:, type:, subtype:, details: nil)
    @parent = parent
    @type = type
    @subtype = subtype.to_sym
    @details = details
    @general_categories = get_general_categories
    @msgs = get_msgs
  end

  def scope
    [parent.underscore.split("/"), "feedback", type]
  end

  def validate
    unless known_subtype?
      raise StandardError,
        "Unknown #{type} subtype for #{parent}: #{subtype}"
    end

    self
  end

  def attributes
    {"type" => type, "subtype" => subtype, "details" => details}
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} " \
      "type: #{type} " \
      "subtype: #{subtype} " \
      "details: #{details}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :parent, :type, :general_categories, :msgs

  def get_general_categories
    hash = I18n.t("feedback")
    return [] unless hash.key?(type)

    hash[type].keys
  end

  def get_msgs = I18n.t(scope.join(".")) || {}

  def known_subtype?
    return true if general_categories.include?(subtype)

    msgs.key?(subtype)
  end
end
