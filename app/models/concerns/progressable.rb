module Progressable
  extend ActiveSupport::Concern

  PENDING = "pending"
  QUEUED = "queued"
  RUNNING = "running"
  COMPLETED = "completed"

  included do
    enum :progress_status, {
      pending: PENDING,
      queued: QUEUED,
      running: RUNNING,
      completed: COMPLETED
    }, prefix: :progress, default: :pending

    def start!
      update(progress_status: RUNNING, started_at: Time.current)
    end
  end
end
