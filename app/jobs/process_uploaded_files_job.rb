require "csv"

class ProcessUploadedFilesJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.start!
    Rails.logger.info "File upload job started"

    if task.activity.files.empty?
      task.fail!({errors: ["At least one file is required"]}) &&
        return
    end

    validated = FilesValidator.call(task.activity.files)
    task.fail!(validated.feedback) && return unless validated.valid?

    validated.data.each { |table| import_from_csv(task, table) }

    # Can update status directly as it's not spawning other jobs
    task.success!
  rescue => e
    Rails.logger.error "#{e.message} -- #{e.backtrace.first(5)}"
    task.fail!({errors: [e.message]})
  end

  def import_from_csv(task, table)
    importer = BatchImporter.new(task)
    table.each { |row| importer.process_row(row.to_h) }
    importer.finalize
  end
end
