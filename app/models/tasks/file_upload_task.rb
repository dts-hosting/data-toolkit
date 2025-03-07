# This task handles iteration of uploaded files (csv or excel),
# creating data items in the database
class Tasks::FileUploadTask < Task
  # triggered to run immediately, no user interaction required
  after_create_commit { run }

  def handler
    FileUploadJob
  end
end
