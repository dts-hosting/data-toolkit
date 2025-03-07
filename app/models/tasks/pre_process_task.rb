# This task handles preprocessing of data items
class Tasks::PreProcessTask < Task
  def dependencies
    [Tasks::FileUploadTask]
  end

  def finalizer
    # PreProcessReportJob
    nil
  end

  def handler
    PreProcessJob
  end
end
