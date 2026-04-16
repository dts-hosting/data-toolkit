require "aws-sdk-cloudwatch"

class PublishQueueSizeJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :publish_queue_size_job, duration: 30.minutes

  CW_NAMESPACE = Rails.configuration.cloudwatch_namespace
  CW_ENVIRONMENT = Rails.configuration.cloudwatch_environment

  def perform
    Rails.logger.info "Starting PublishQueueSizeJob"

    dimensions = [
      {name: "Environment", value: CW_ENVIRONMENT}
    ]

    metric_data = [{
      metric_name: "Jobs",
      dimensions: dimensions,
      value: SolidQueue::ReadyExecution.count.to_f,
      unit: "Count"
    }]

    cloudwatch_client.put_metric_data(namespace: CW_NAMESPACE, metric_data: metric_data)

    Rails.logger.info "Completed PublishQueueSizeJob"
  rescue => e
    Rails.logger.error "PublishQueueSizeJob unexpected error: #{e.class} #{e.message}"
    raise
  end

  private

  def cloudwatch_client
    @cloudwatch_client ||= Aws::CloudWatch::Client.new(
      region: ENV["AWS_REGION"]
    )
  end
end
