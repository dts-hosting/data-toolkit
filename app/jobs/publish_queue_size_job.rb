class PublishQueueSizeJob < ApplicationJob
  queue_as :high_priority

  def perform
    return unless CloudWatch.enabled?

    Rails.logger.info "Starting PublishQueueSizeJob"

    metric_data = [{
      metric_name: "Jobs",
      dimensions: [{name: "Environment", value: CloudWatch.env}],
      value: SolidQueue::ReadyExecution.count.to_f,
      unit: "Count"
    }]

    CloudWatch.client.put_metric_data(namespace: CloudWatch.namespace, metric_data: metric_data)

    Rails.logger.info "Completed PublishQueueSizeJob"
  rescue => e
    Rails.logger.error "PublishQueueSizeJob unexpected error: #{e.class} #{e.message}"
    raise
  end
end
