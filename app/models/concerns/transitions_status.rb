module TransitionsStatus
  extend ActiveSupport::Concern

  # Statuses that indicate completion (success, failure, or requiring review)
  COMPLETION_STATUSES = %w[failed review succeeded].freeze

  included do
    def completed?
      COMPLETION_STATUSES.include?(status)
    end

    def fail!(feedback = nil)
      params = {status: "failed", completed_at: Time.current, feedback: feedback}.compact
      update!(**params)
    end

    def start!
      update!(status: "running", started_at: Time.current)
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
