# Provides auto-advance workflow behavior for activities.
# Monitors activity updates and logs workflow state changes.
module AutoAdvanceable
  extend ActiveSupport::Concern

  included do
    after_update_commit :handle_advance
  end

  private

  # Handles auto-advance logic after activity updates.
  # TODO: for the moment we're just logging, but this would be a good spot for notifications
  def handle_advance
    return unless config.fetch("auto_advance", true)

    # if auto advanced transitioned from true -> false
    if saved_change_to_auto_advanced? && saved_change_to_auto_advanced.first == true && !auto_advanced
      Rails.logger.info "Activity #{id}: Auto-advance disabled"
    end

    # if the current_task is the last task and it was successful
    if current_task == tasks.last && current_task&.outcome_succeeded?
      Rails.logger.info "Activity #{id}: Workflow completed successfully"
    end
  end
end
