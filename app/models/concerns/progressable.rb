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
  end
end
