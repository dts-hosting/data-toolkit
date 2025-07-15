module TransitionsStatus
  extend ActiveSupport::Concern

  # Statuses that indicate completion (success, failure, or requiring review)
  PROGRESSED_STATUSES = %w[failed review succeeded].freeze

  included do
    def fail!(feedback = nil)
      params = {status: "failed", completed_at: Time.current, feedback: feedback}.compact
      update!(**params)
    end

    def start!
      update!(status: "running",
        started_at: Time.current,
        feedback: Feedback.new(feedback_context))
    end

    def success!
      update!(status: "succeeded", completed_at: Time.current)
    end

    def suspend!(feedback = nil)
      params = {status: "review", completed_at: Time.current, feedback: feedback}.compact
      update!(**params)
    end
  end
end
