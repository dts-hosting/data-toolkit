require "csv"

class FileUploadJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.update(status: "running", started_at: Time.current)
    Rails.logger.info "File upload job started"

    task.fail! && return if task.activity.files.empty?

    task.activity.files.each do |file|
      # TODO: determine content type: create_data_items_from_excel(task, file)
      create_data_items_from_csv(task, file)
    end

    # Can update status directly as it's not spawning other jobs
    task.success!
  end

  # TODO: optimize for performance using bulk insert
  def create_data_items_from_csv(task, file)
    file.open do |f|
      CSV.foreach(f.path, headers: true).with_index do |row, index|
        task.activity.data_items.create(current_task_id: task.id, position: index, data: row.to_h)
      end
    end
  end
end
