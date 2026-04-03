# Provides "advance" workflow behavior for activities
module Advanceable
  extend ActiveSupport::Concern

  included do
    def advance
      return unless can_advance?

      resume_runtime_auto_advance!
      next_task&.run
    end

    # attempt to move on to the next task if the current task
    # is completed, was successful and auto advance is enabled.
    # This is called by Runnable -> handle_completion.
    def trigger_auto_advance
      return unless can_advance?

      if current_task.outcome_succeeded? && auto_advance_config_enabled?
        next_task&.run
      else
        current_task.finalizer&.perform_later(current_task)
        pause_runtime_auto_advance!
      end
    end

    def can_advance?
      current_task&.progress_completed? || false
    end

    private

    def auto_advance_config_enabled?
      config.fetch("auto_advance", true)
    end

    def pause_runtime_auto_advance!
      update(auto_advance: false) if auto_advance?
    end

    def resume_runtime_auto_advance!
      update(auto_advance: true) unless auto_advance?
    end
  end
end
