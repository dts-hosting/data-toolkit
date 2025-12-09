# Encapsulates state/behavior for progressing a runnable
# or other model that needs to track a "progress" state.
module Progressable
  extend ActiveSupport::Concern

  PENDING = "pending"
  QUEUED = "queued"
  RUNNING = "running"
  COMPLETED = "completed"

  included do
    validates :progress_status, presence: true

    enum :progress_status, {
      pending: PENDING,
      queued: QUEUED,
      running: RUNNING,
      completed: COMPLETED
    }, prefix: :progress, default: :pending

    # Note: default done! implementation, overriden by Runnable
    def done!(feedback = nil)
      params = {
        progress_status: COMPLETED,
        completed_at: Time.current,
        feedback: feedback
      }.compact
      update!(**params)
    end

    def start!
      update(progress_status: RUNNING, started_at: Time.current)
    end
  end
end
