class Tasks::PreProcessTask < Task
  def dependencies
    [Tasks::FileUploadTask]
  end

  def finalizer
    # PreProcessReportJob
  end

  def handler
    # PreProcessJob
  end
end
