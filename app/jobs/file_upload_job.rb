class FileUploadJob < ApplicationJob
  queue_as :default

  def perform(task)
    task.update(status: "running", started_at: Time.current)
    Rails.logger.info "File upload job started"
    sleep 10
    task.update(status: "succeeded", completed_at: Time.current)
    Rails.logger.info "File upload job finished"
  end
end
