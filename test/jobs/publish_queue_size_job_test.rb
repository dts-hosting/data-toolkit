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
      }]
    )
    CloudWatch.stubs(:enabled?).returns(true)
    CloudWatch.stubs(:client).returns(client)
    CloudWatch.stubs(:namespace).returns("Test/Queue")
    CloudWatch.stubs(:env).returns("test")

    PublishQueueSizeJob.perform_now
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
end
