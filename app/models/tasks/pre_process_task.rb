# This task handles preprocessing of data items
module Tasks
  class PreProcessTask < Task
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
end
