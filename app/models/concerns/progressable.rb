module Progressable
  extend ActiveSupport::Concern

  included do
    enum :progress_status, {
      pending: "pending",
      queued: "queued",
      running: "running",
      completed: "completed"
    }, prefix: :progress, default: :pending

    def start!
      update(progress_status: "running", started_at: Time.current)
    end
  end
end
