module Feedbackable
  extend ActiveSupport::Concern

  def feedback_for
    return Feedback.new(feedback_context) unless feedback_before_type_cast
    return Feedback.new(feedback_context) if feedback_before_type_cast.empty?

    Feedback.new.from_json(feedback_before_type_cast)
  end
end
