class Tasks::FileUploadTask < Task
  # triggered to run immediately, no user interaction required
  after_create_commit { run }

  def handler
    # FileUploadJob
  end
end
