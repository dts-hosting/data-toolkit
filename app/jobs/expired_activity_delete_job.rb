class ExpiredActivityDeleteJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :expired_activity_delete_job, duration: 30.minutes

  EXPIRED_BATCH_SIZE = 10

  def perform
    Rails.logger.info "Starting ExpiredActivityDeleteJob"
    destroy_expired_activities(Activity.expired_failed)
    destroy_expired_activities(Activity.expired_non_failed)
    Rails.logger.info "Completed ExpiredActivityDeleteJob"
  end

  private

  def destroy_expired_activities(activities)
    activities.find_in_batches(batch_size: EXPIRED_BATCH_SIZE) do |batch|
      batch.each(&:destroy)
      Rails.logger.info "Deleted #{batch.size} activities"
    rescue => e
      Rails.logger.error "Error processing batch: #{e.message}"
    end
  end
end
