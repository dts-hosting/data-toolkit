require "aws-sdk-cloudwatch"
require "solid_queue/cli"

class PublishQueueSizeJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :expired_activity_delete_job, duration: 30.minutes

  CW_NAMESPACE = ENV.fetch("CW_NAMESPACE", "DataToolkit/Queue")
  CW_ENVIRONMENT = ENV.fetch("CW_ENVIRONMENT", "UAT")

  def perform
    Rails.logger.info "Starting PublishQueueSizeJob"
    
    def cloudwatch_client
      @cloudwatch_client ||= Aws::CloudWatch::Client.new(region: ENV.fetch("AWS_REGION"))
    end

    dimensions = [{name: "Environment", value: CW_ENVIRONMENT},
      {name: "QueueName", value: "default"}]

    metric_data = {metric_name: "Jobs", dimensions: dimensions, value: SolidQueue::ReadyExecution.count, unit: "Count"}

    cloudwatch_client.put_metric_data(namespace: CW_NAMESPACE, metric_data: metric_data)

    Rails.logger.info "Completed PublishQueueSizeJob"
  end

end
