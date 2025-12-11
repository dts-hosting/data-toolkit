# Provides history tracking for activities.
module Historical
  extend ActiveSupport::Concern

  included do
    before_destroy :create_history
  end

  # Builds a summary hash of the activity's current state for history records.
  def summary
    return {} if tasks.empty?

    task = current_task || next_task
    {
      activity_user: user.email_address,
      activity_url: user.cspace_url,
      activity_type: display_name,
      activity_label: label,
      activity_data_config_type: data_config.config_type,
      activity_data_config_record_type: data_config.record_type,
      activity_created_at: created_at,
      task_type: task.display_name,
      task_status: task.status,
      task_feedback: task.feedback,
      task_started_at: task.started_at || Time.current,
      task_completed_at: task.completed_at
    }
  end

  private

  def create_history
    return if tasks.empty?

    History.create!(summary)
    tasks.destroy_all # we do this here to have access to task for history
  rescue => e
    Rails.logger.error "Failed to create history for activity #{id}: #{e.message}"
    errors.add(:base, "Unable to create history record")
    throw(:abort)
  end
end
