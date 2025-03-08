require "csv"
# TODO: require "roo"

class FileUploadJob < ApplicationJob
  queue_as :default

  # This job iterates files to create data items
  def perform(task)
    task.start!
    Rails.logger.info "File upload job started"

    task.fail!({errors: ["At least one file is required"]}) && return if task.activity.files.empty?

    task.activity.files.each do |file|
      # TODO: determine content type: import_from_excel(task, file)
      import_from_csv(task, file)
    end

    # Can update status directly as it's not spawning other jobs
    task.success!
  rescue => e
    Rails.logger.error e.message
    task.fail!({errors: [e.message]})
  end

  def import_from_csv(task, file)
    importer = BatchImporter.new(task)
    file.open do |f|
      CSV.foreach(f.path, headers: true) do |row|
        importer.process_row(row.to_h)
      end
    end
    importer.finalize
  end

  def import_from_excel(task, file)
    # TODO: do it
  end
end
