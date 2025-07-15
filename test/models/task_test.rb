require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @task = Task.new(
      type: "Tasks::ProcessUploadedFiles",
      activity: create_activity
    )
  end

  test "should be valid with required attributes" do
    assert @task.valid?
  end

  test "should require type" do
    @task.type = nil
    assert_not @task.valid?
    assert_includes @task.errors[:type], "can't be blank"
  end

  test "should require activity" do
    @task.activity = nil
    assert_not @task.valid?
    assert_includes @task.errors[:activity], "must exist"
  end

  test "should require status" do
    @task.status = nil
    assert_not @task.valid?
    assert_includes @task.errors[:status], "can't be blank"
  end

  test "should have default status of pending" do
    task = Task.new
    assert_equal "pending", task.status
  end

  test "should allow valid status values" do
    valid_statuses = [:pending, :queued, :running, :succeeded, :review, :failed]

    valid_statuses.each do |status|
      @task.status = status
      assert @task.valid?, "#{status} should be a valid status"
    end
  end

  test "should track timestamps for task progression" do
    @task.save!

    @task.started_at = Time.current
    @task.status = :running
    @task.save!
    assert_not_nil @task.started_at

    @task.completed_at = Time.current
    @task.status = :succeeded
    @task.save!
    assert_not_nil @task.completed_at
  end

  test "should attach files" do
    @task.save!

    file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    @task.files.attach(file)
    assert @task.files.attached?
    assert_equal 1, @task.files.count
  end

  # dependencies
  test "should handle dependencies correctly" do
    # TODO: flexible handling of stuff like this ...
    activity = create_activity(
      {
        type: "Activities::CreateOrUpdateRecords",
        config: {action: "create"},
        data_config: create_data_config_record_type({record_type: "acquisitions"}),
        files: [
          Rack::Test::UploadedFile.new(
            Rails.root.join("test/fixtures/files/test.csv"),
            "text/csv"
          )
        ]
      }
    )
    first_task = activity.tasks[0]
    dependent_task = activity.tasks[1]

    assert_includes dependent_task.dependencies, first_task.class
    assert_not dependent_task.ok_to_run?

    first_task.success!
    assert dependent_task.ok_to_run?
  end

  # status transitions
  test "should execute start! method correctly" do
    @task.save!
    @task.start!

    assert_equal "running", @task.status
    assert_not_nil @task.started_at
  end

  test "should execute fail! method correctly when feedback is empty Hash" do
    @task.save!
    @task.fail!({})

    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
    feedback = @task.feedback_for
    refute feedback.displayable?
  end

  test "should execute fail! method correctly when feedback is valid feedback Hash" do
    feedback_hash = {"parent" => "Tasks::ProcessUploadedFiles",
                     "errors" =>
     [{"type" => "error",
       "subtype" => "csvlint_invalid_encoding",
       "details" => "row 2",
       "prefix" => "invalid_encoding.csv"},
       {"type" => "error",
        "subtype" => "csv_stdlib_malformed_csv",
        "details" => "Invalid byte sequence in UTF-8 in line 2.",
        "prefix" => "invalid_encoding.csv"}],
                     "warnings" => [],
                     "messages" => []}

    @task.save!
    @task.fail!(feedback_hash)

    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
    feedback = @task.feedback_for
    refute feedback.ok?
  end

  # Full backtrace for the expected error the following test should cause:
  #   Error:
  #   TaskTest#test_should_execute_fail!_method_correctly_when_feedback_is_invalid_feedback_Hash:
  #   NoMethodError: undefined method 'underscore' for nil
  #       App/lib/feedback_element.rb:73:in 'FeedbackElement#parent_scope'
  #       app/lib/feedback_element.rb:66:in 'FeedbackElement#get_msgs'
  #       app/lib/feedback_element.rb:22:in 'FeedbackElement#initialize'
  #       app/models/feedback.rb:51:in 'Class#new'
  #       app/models/feedback.rb:51:in 'Feedback#add_to_attribute'
  #       app/models/feedback.rb:67:in 'Kernel#public_send'
  #       app/models/feedback.rb:67:in 'block (2 levels) in Feedback#attributes='
  #       app/models/feedback.rb:65:in 'Array#each'
  #       app/models/feedback.rb:65:in 'block in Feedback#attributes='
  #       app/models/feedback.rb:59:in 'Hash#each'
  #       app/models/feedback.rb:59:in 'Feedback#attributes='
  #       app/models/concerns/feedbackable.rb:8:in 'Feedbackable#feedback_for'
  #       test/models/task_test.rb:156:in 'block in <class:TaskTest>'
  test ":feedback_for should raise exception when invalid feedback Hash has been saved" do
    feedback_hash = {"errors" =>
                       [{"type" => "error",
                         "subtype" => "csvlint_invalid_encoding",
                         "details" => "row 2",
                         "prefix" => "invalid_encoding.csv"}]}
    @task.save!
    @task.fail!(feedback_hash)

    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
    assert_equal ["errors"], @task.feedback.keys
    assert_raises(NoMethodError, "undefined method 'underscore' for nil") do
      @task.feedback_for
    end
  end

  test "should execute fail! method correctly when feedback is Feedback Object" do
    @task.save!
    feedback = @task.feedback_for
    feedback.add_to_errors(subtype: :csvlint_invalid_encoding, details: "row 2",
      prefix: "invalid_encoding.csv")
    @task.fail!(feedback)

    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
    refute feedback.ok?
    assert_equal 1, @task.feedback["errors"].length
  end

  test "should execute success! method correctly" do
    @task.save!
    @task.success!

    assert_equal "succeeded", @task.status
    assert_not_nil @task.completed_at
  end

  test "should execute suspend! method correctly" do
    @task.save!
    @task.suspend!

    assert_equal "review", @task.status
    assert_not_nil @task.completed_at
  end

  # progress checking
  test "progress should be 0 when status is pending" do
    @task.status = "pending"
    assert_equal 0, @task.progress
  end

  test "progress should be 0 when status is queued" do
    @task.status = "queued"
    assert_equal 0, @task.progress
  end

  test "progress should be 100 when status is succeeded" do
    @task.status = "succeeded"
    assert_equal 100, @task.progress
  end

  test "progress should be 100 when status is failed" do
    @task.status = "failed"
    assert_equal 100, @task.progress
  end

  test "progress should be 100 when status is review" do
    @task.status = "review"
    assert_equal 100, @task.progress
  end

  test "progress should calculate percentage when status is running" do
    @task.save!
    create_data_items_for_task(@task)
    @task.status = "running"

    @task.data_items.first.update(status: "succeeded")
    @task.data_items.last.update(status: "succeeded")

    # Should be 40% complete (2 out of 5 items)
    assert_equal 40.0, @task.progress
  end

  test "progress should include review status items in calculation" do
    @task.save!
    create_data_items_for_task(@task)
    @task.status = "running"

    @task.data_items[0].update(status: "succeeded")
    @task.data_items[1].update(status: "review")

    # Should be 40% complete (2 out of 5 items, both succeeded and review count as progressed)
    assert_equal 40.0, @task.progress
  end

  test "progress should be 0 when running with no data items" do
    @task.status = "running"
    assert_equal 0, @task.progress
  end

  test "progress should trigger finish_up when reaching 100%" do
    @task.save!
    create_data_items_for_task(@task)
    @task.status = "running"
    @task.save!

    @task.data_items.update_all(status: "succeeded")
    @task.data_items.last.update(status: "succeeded")
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "succeeded", @task.status
    assert_not_nil @task.completed_at
  end

  test "progress should set status to failed if any items failed" do
    @task.save!
    create_data_items_for_task(@task)
    @task.status = "running"
    @task.save!

    @task.data_items.update_all(status: "succeeded")
    @task.data_items.last.update(status: "failed")
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
  end

  test "progress should set status to review if items are in review status" do
    @task.save!
    create_data_items_for_task(@task)
    @task.status = "running"
    @task.save!

    @task.data_items.update_all(status: "succeeded")
    @task.data_items.last.update(status: "review")
    @task.reload

    assert_equal 100, @task.progress
    assert_equal "review", @task.status
    assert_not_nil @task.completed_at
  end
end
