# frozen_string_literal: true

# Abstract class for FeedbackError, FeedbackWarning, and FeedbackMessage
#  to inherit from
class FeedbackElement
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_reader :type, :subtype, :details, :prefix

  # @param parent [String] class name of the instance whose Feedback this
  #   element belongs to
  # @param type [:error, :warning, :message]
  # @param subtype [Symbol]
  def initialize(parent:, type:, subtype:, details: nil, prefix: nil)
    @parent = parent
    @type = type
    @subtype = subtype.to_sym
    @details = set_details(details)
    @prefix = prefix
    @general_categories = get_general_categories
    @msgs = get_msgs
  end


  def validate
    unless known_subtype?
      raise FeedbackSubtypeError,
        "Unknown #{type} subtype for #{parent}: #{subtype}"
    end

    self
  end

  def attributes
    {"type" => type, "subtype" => subtype, "details" => details,
     "prefix" => prefix}
  end

  def to_s
    "<##{self.class}:#{object_id.to_s(8)} " \
      "type: #{type} " \
      "subtype: #{subtype} " \
      "details: #{details} " \
      "prefix: #{prefix}>"
  end
  alias_method :inspect, :to_s

  private

  attr_reader :parent, :general_categories, :msgs

  def get_general_categories
    hash = I18n.t("feedback")
    return [] unless hash.key?(type.to_sym)

    hash[type.to_sym].keys
  end

  def get_msgs
    hash = I18n.t(parent_scope)
    return {} if hash.is_a?(String) && hash.start_with?("Translation missing")

    hash
  end

  def parent_scope
    @parent_scope ||= [parent.underscore.split("/"), "feedback", type].join(".")
  end

  def set_details(details)
    return details unless details.is_a?(Exception)

    loc = details.backtrace
      .find { |e| e.start_with?(Rails.root.to_s) }
    "#{details.class.name}: #{details.message}: #{loc}"
  end

  def known_subtype?
    return true if general?

    msgs.key?(subtype)
  end

  def general? = general_categories.include?(subtype)
end
