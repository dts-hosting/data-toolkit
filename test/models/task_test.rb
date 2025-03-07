require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @task = Task.new(
      type: "Tasks::FileUploadTask",
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
    valid_statuses = [:pending, :queued, :running, :succeeded, :failed]

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

  # progress checking
  test "progress should be 0 when status is pending" do
    @task.status = :pending
    assert_equal 0, @task.progress
  end

  test "progress should be 0 when status is queued" do
    @task.status = :queued
    assert_equal 0, @task.progress
  end

  test "progress should be 100 when status is succeeded" do
    @task.status = :succeeded
    assert_equal 100, @task.progress
  end

  test "progress should be 100 when status is failed" do
    @task.status = :failed
    assert_equal 100, @task.progress
  end

  test "progress should calculate percentage when status is running" do
    @task.save!
    @task.status = :running

    3.times { |i| @task.activity.data_items.create!(status: :pending, position: i + 1, data: {content: "Data #{i + 1}"}) }
    2.times { |i| @task.activity.data_items.create!(status: :succeeded, position: i + 4, data: {content: "Data #{i + 4}"}) }

    # Should be 40% complete (2 out of 5 items)
    assert_equal 40.0, @task.progress
  end

  test "progress should be 0 when running with no data items" do
    @task.status = :running
    assert_equal 0, @task.progress
  end

  test "progress should trigger finish_up when reaching 100%" do
    @task.save!
    @task.status = :running
    @task.save!

    3.times { |i| @task.activity.data_items.create!(status: :succeeded, position: i + 1, data: {content: "Data #{i + 1}"}) }

    @task.progress

    assert_equal "succeeded", @task.status
    assert_not_nil @task.completed_at
  end

  test "progress should set status to failed if any items failed" do
    @task.save!
    @task.status = :running
    @task.save!

    2.times { |i| @task.activity.data_items.create!(status: :failed, position: i + 1, data: {content: "Data #{i + 1}"}) }
    @task.activity.data_items.create!(status: :failed, position: 3, data: {content: "Data 3"})

    @task.progress

    assert_equal "failed", @task.status
    assert_not_nil @task.completed_at
  end
end
