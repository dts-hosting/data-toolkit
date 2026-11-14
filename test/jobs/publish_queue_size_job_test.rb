require "test_helper"

class PublishQueueSizeJobTest < ActiveJob::TestCase
  setup do
    SolidQueue::Job.delete_all
  end

  test "publishes the ready execution count" do
    # SolidQueue::Job.create! dispatches a ReadyExecution automatically
    3.times { SolidQueue::Job.create!(queue_name: "default", class_name: "NoopJob", arguments: {}) }

    client = mock("cloudwatch")
    client.expects(:put_metric_data).with(
      namespace: "Test/Queue",
      metric_data: [{
        metric_name: "Jobs",
        dimensions: [{name: "Environment", value: "test"}],
        value: 3.0,
        unit: "Count"
      }, {
        metric_name: "DemandSlots",
        dimensions: [{name: "Environment", value: "test"}],
        value: 3.0,
        unit: "Count"
      }]
    )
    CloudWatch.stubs(:enabled?).returns(true)
    CloudWatch.stubs(:client).returns(client)
    CloudWatch.stubs(:namespace).returns("Test/Queue")
    CloudWatch.stubs(:env).returns("test")

    PublishQueueSizeJob.perform_now
  end

  test "demand slots cap each client's CollectionSpace jobs at the limit" do
    5.times { create_job(concurrency_key: "CollectionSpaceApi/https://a.example.org") }
    2.times { create_job(concurrency_key: "CollectionSpaceApi/https://b.example.org") }
    4.times { create_job } # unlimited jobs each need a slot

    assert_equal 3 + 2 + 4, PublishQueueSizeJob.demand_slots(cap: 3)
  end

  test "demand slots count blocked executions toward capped demand" do
    key = "CollectionSpaceApi/https://a.example.org"
    5.times { create_job(concurrency_key: key) }
    block(create_job(concurrency_key: key))

    assert_equal 3, PublishQueueSizeJob.demand_slots(cap: 3)
    assert_equal 6, PublishQueueSizeJob.demand_slots(cap: 100)
  end

  test "demand slots ignore finished jobs" do
    create_job(concurrency_key: "CollectionSpaceApi/https://a.example.org", finished_at: Time.current)

    assert_equal 0, PublishQueueSizeJob.demand_slots(cap: 3)
  end

  test "does nothing when CloudWatch is disabled" do
    CloudWatch.stubs(:enabled?).returns(false)
    CloudWatch.expects(:client).never

    PublishQueueSizeJob.perform_now
  end

  test "runs on high_priority queue ahead of default priority" do
    assert_equal "high_priority", PublishQueueSizeJob.new.queue_name
    assert_operator PublishQueueSizeJob.new.priority, :<, 0
  end

  private

  def create_job(**attrs)
    SolidQueue::Job.create!({queue_name: "default", class_name: "NoopJob", arguments: {}}.merge(attrs))
  end

  # Move a freshly created (ready) job to the blocked state
  def block(job)
    job.ready_execution.destroy!
    SolidQueue::BlockedExecution.create!(job: job)
  end
end
