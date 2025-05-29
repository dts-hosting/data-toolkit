module TransitionsStatus
  extend ActiveSupport::Concern

  included do
    def fail!(feedback = "")
      update!(status: "failed", completed_at: Time.current, feedback: feedback)
    end

    def start!
      context = if is_a?(DataItem)
        current_task.class.name
      else
        self.class.name
      end
      feedback = Feedback.new(context)
      update!(status: "running", started_at: Time.current, feedback: feedback)
    end

    def success!
      update!(status: "succeeded", completed_at: Time.current)
    end
  end
end
