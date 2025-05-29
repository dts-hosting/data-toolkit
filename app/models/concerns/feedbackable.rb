module Feedbackable
  extend ActiveSupport::Concern

  def feedback_for = Feedback.new.from_json(feedback_before_type_cast)
end
