# Provides "advance" workflow behavior for activities
module Advanceable
  extend ActiveSupport::Concern

  included do
    def advance
      return unless can_advance?

      next_task&.run
      # reset auto_advance in case previously disabled
      update(auto_advance: true) unless auto_advance?
    end

    # attempt to move on to the next task if the current task
    # is completed, was successful and auto advance is enabled.
    # This is called by Runnable -> handle_completion.
    def trigger_auto_advance
      return unless can_advance?

      if current_task.outcome_succeeded? && config.fetch("auto_advance", true)
        next_task&.run
      else
        current_task.finalizer&.perform_later(current_task)
        update(auto_advance: false) if auto_advance?
      end
    end

    def can_advance?
      current_task.progress_completed?
    end
  end
end
