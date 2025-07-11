class ExpiredActivityDeleteJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :expired_activity_delete_job, duration: 30.minutes

  EXPIRED_BATCH_SIZE = 10
  FAILED_EXPIRATION_DAYS = 7
  NON_FAILED_EXPIRATION_DAYS = 3

  def perform
    Rails.logger.info "Starting ExpiredActivityDeleteJob"
    destroy_expired_activities(failed_activities)
    destroy_expired_activities(non_failed_activities)
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

  def failed_activities
    Activity.joins(:tasks)
      .where(tasks: {status: "failed"})
      .where(updated_at: ...FAILED_EXPIRATION_DAYS.days.ago)
      .distinct
  end

  def non_failed_activities
    failed_activity_ids = Activity.joins(:tasks)
      .where(tasks: {status: "failed"})
      .select(:id)

    Activity.where(updated_at: ...NON_FAILED_EXPIRATION_DAYS.days.ago)
      .where.not(id: failed_activity_ids)
  end
end
