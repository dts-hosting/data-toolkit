require "csv"

class ProcessUploadedFilesJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.start!
    Rails.logger.info "File upload job started"

    if task.activity.files.empty? && !task.activity.requires_files?
      task.done!(Task::SUCCEEDED) && return
    end

    feedback = task.feedback_for

    if task.activity.files.empty?
      feedback.add_to_errors(subtype: :no_file)
      task.done!(Task::FAILED, feedback) && return
    end

    validated = FilesValidator.new(
      files: task.activity.files,
      taskname: task.feedback_context,
      feedback: feedback
    ).call
    unless validated.valid?
      task.done!(Task::FAILED, feedback) && return
    end

    validated.data.each { |table| import_from_csv(task, table) }

    task.reload
    if task.activity.data_items_count.zero?
      feedback.add_to_errors(subtype: :no_data)
      task.done!(Task::FAILED, feedback) && return
    end

    task.done!(Task::SUCCEEDED)
  rescue => e
    Rails.logger.error "#{e.message} -- #{e.backtrace.first(5)}"
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.done!(Task::FAILED, feedback) && return
  end

  def import_from_csv(task, table)
    importer = BatchImporter.new(task)
    table.each { |row| importer.process_row(row.to_h) }
    importer.finalize
  end
end
