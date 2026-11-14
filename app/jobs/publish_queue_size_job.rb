# Publishes queue metrics for worker autoscaling:
#   Jobs        - ready executions (informational)
#   DemandSlots - worker slots that could be used right now (drives alarms)
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

  # Worker slots that could be put to use right now. Autoscaling must follow
  # this rather than the raw backlog: a client with 20k queued CollectionSpace
  # jobs can only occupy `cap` slots, so workers beyond that would sit idle.
  # Live = not finished, failed or scheduled for later (ready, claimed or
  # blocked). Capped jobs count at most `cap` per client; everything else
  # (unlimited action jobs, handlers, finalizers) needs one slot each.
  def self.demand_slots(cap: ActionJob::CLIENT_CONCURRENCY)
    live = SolidQueue::Job.where(finished_at: nil)
      .where.missing(:failed_execution, :scheduled_execution)
    prefix = "#{ActionJob::CONCURRENCY_GROUP}/%"

    capped = live.where("concurrency_key LIKE ?", prefix).group(:concurrency_key).count
    others = live.where("concurrency_key IS NULL OR concurrency_key NOT LIKE ?", prefix).count

    capped.values.sum { |n| [n, cap].min } + others
  end

  private

  def metric_data
    dimensions = [{name: "Environment", value: CloudWatch.env}]
    [
      {metric_name: "Jobs", dimensions: dimensions, value: SolidQueue::ReadyExecution.count.to_f, unit: "Count"},
      {metric_name: "DemandSlots", dimensions: dimensions, value: self.class.demand_slots.to_f, unit: "Count"}
    ]
  end
end
