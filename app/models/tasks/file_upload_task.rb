# This task handles iteration of uploaded files (csv or excel),
# creating data items in the database
module Tasks
  class FileUploadTask < Task
    # triggered to run immediately, no user interaction required
    after_create_commit { run }

    def handler
      FileUploadJob
    end
  end
end
