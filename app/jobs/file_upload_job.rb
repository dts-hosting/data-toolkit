class FileUploadJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.update(status: "running", started_at: Time.current)
    Rails.logger.info "File upload job started"

    # Just testing, this would really come from the files ...
    task.activity.data_items.create(position: 0, data: {":key": "value"})
    sleep 10

    task.activity.data_items.update_all(status: :succeeded)
  end
end
