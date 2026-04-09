require "test_helper"

class PublishQueueSizeJobTest < ActiveJob::TestCase
  setup do
    @mock_cw = mock("cloudwatch_client")
    Aws::CloudWatch::Client.stubs(:new).with(region: "us-east-1").returns(@mock_cw)
    ENV["AWS_REGION"] = "us-east-1"
  end

  teardown do
    ENV.delete("AWS_REGION")
  end

  test "publishes ready job count to CloudWatch with correct namespace and dimensions" do
    SolidQueue::ReadyExecution.stubs(:count).returns(7)

    @mock_cw.expects(:put_metric_data).with(
      namespace: PublishQueueSizeJob::CW_NAMESPACE,
      metric_data: {
        metric_name: "Jobs",
        dimensions: [
          {name: "Environment", value: PublishQueueSizeJob::CW_ENVIRONMENT},
          {name: "QueueName", value: "default"}
        ],
        value: 7,
        unit: "Count"
      }
    )

    PublishQueueSizeJob.perform_now
  end

  test "publishes zero when the queue is empty" do
    SolidQueue::ReadyExecution.stubs(:count).returns(0)

    @mock_cw.expects(:put_metric_data).with(
      namespace: PublishQueueSizeJob::CW_NAMESPACE,
      metric_data: {
        metric_name: "Jobs",
        dimensions: [
          {name: "Environment", value: PublishQueueSizeJob::CW_ENVIRONMENT},
          {name: "QueueName", value: "default"}
        ],
        value: 0,
        unit: "Count"
      }
    )

    PublishQueueSizeJob.perform_now
  end
end
