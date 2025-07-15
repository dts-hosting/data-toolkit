require "csv"

class ProcessUploadedFilesJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.start!
    Rails.logger.info "File upload job started"

    feedback = task.feedback_for

    if task.activity.files.empty?
      feedback.add_to_errors(subtype: :no_file)
      task.fail!(feedback) && return
    end

    validated = FilesValidator.new(
      files: task.activity.files,
      taskname: task.feedback_context,
      feedback: feedback
    ).call
    task.fail!(feedback) && return unless validated.valid?

    validated.data.each { |table| import_from_csv(task, table) }

    # Can update status directly as it's not spawning other jobs
    task.success!
  rescue => e
    Rails.logger.error "#{e.message} -- #{e.backtrace.first(5)}"
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.fail!(feedback)
  end

  def import_from_csv(task, table)
    importer = BatchImporter.new(task)
    table.each { |row| importer.process_row(row.to_h) }
    importer.finalize
  end
end
