# Provides "advance" workflow behavior for activities
# (this refers to transitioning to the next task)
# Monitors activity updates and logs workflow state changes.
module Advanceable
  extend ActiveSupport::Concern

  included do
    after_update_commit :track_advance
  end

  def advance
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

  private

  # Track auto-advance logic after activity updates.
  # TODO: for the moment we're just logging, but this would be a good spot for notifications
  def track_advance
    # if auto advanced transitioned from true -> false
    if saved_change_to_auto_advance? && saved_change_to_auto_advance.first == true && !auto_advance?
      Rails.logger.info "Activity #{id}: Auto-advance disabled"
    end

    if done?
      Rails.logger.info "Activity #{id}: Workflow completed successfully"
    end
  end
end
