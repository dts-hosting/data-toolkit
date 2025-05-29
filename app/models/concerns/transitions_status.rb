module TransitionsStatus
  extend ActiveSupport::Concern

  included do
    def fail!(feedback = {})
      update!(status: "failed", completed_at: Time.current, feedback: feedback)
    end

    def start!
      update!(status: "running",
        started_at: Time.current,
        feedback: Feedback.new(feedback_context))
    end

    def success!
      update!(status: "succeeded", completed_at: Time.current)
    end
  end
end
