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

    # Create a test file
    file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("test content"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    @task.files.attach(file)
    assert @task.files.attached?
    assert_equal 1, @task.files.count
  end
end
