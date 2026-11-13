# Publishes the ready-job backlog that drives worker autoscaling.
# Runs on :high_priority, which has dedicated worker threads, so it is
# unaffected by a saturated default queue. Runs every minute to match the
# 60s alarm period.
class PublishQueueSizeJob < ApplicationJob
  queue_as :high_priority
  queue_with_priority(-10)

  def perform
    return unless CloudWatch.enabled?

    Rails.logger.info "Starting PublishQueueSizeJob"

    CloudWatch.client.put_metric_data(namespace: CloudWatch.namespace, metric_data: metric_data)

    Rails.logger.info "Completed PublishQueueSizeJob"
  rescue => e
    Rails.logger.error "PublishQueueSizeJob unexpected error: #{e.class} #{e.message}"
    raise
  end

  private

  def metric_data
    [{
      metric_name: "Jobs",
      dimensions: [{name: "Environment", value: CloudWatch.env}],
      value: SolidQueue::ReadyExecution.count.to_f,
      unit: "Count"
    }]
  end
end
