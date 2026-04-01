require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @reader = users(:reader)
    @external_user = users(:external)

    @data_config = create_data_config_record_type
    file = fixture_file_upload(Rails.root.join("test/fixtures/files/test.csv"), "text/csv")
    activity_attrs = {type: :create_or_update_records, data_config: @data_config, files: [file]}

    sign_in(@admin)

    @admin_activity = create_activity(**activity_attrs, user: @admin)
    @reader_activity = create_activity(**activity_attrs, user: @reader)
    @external_activity = create_activity(**activity_attrs, user: @external_user)
  end

  test "should show task for own activity" do
    task = @admin_activity.tasks.first
    get activity_task_url(@admin_activity, task)
    assert_response :success
  end

  test "should show task for same organization activity" do
    task = @reader_activity.tasks.first
    get activity_task_url(@reader_activity, task)
    assert_response :success
  end

  test "should not show task for different organization" do
    task = @external_activity.tasks.first
    get activity_task_url(@external_activity, task)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not show task with invalid activity" do
    task = @admin_activity.tasks.first
    get activity_task_url(999, task)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not show task with invalid task id" do
    get activity_task_url(@admin_activity, 999)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "owner can run task" do
    task = @admin_activity.tasks.first
    Task.any_instance.stubs(:run)
    post run_activity_task_url(@admin_activity, task)
    assert_redirected_to activity_path(@admin_activity)
    assert_equal "Task was successfully queued.", flash[:notice]
  end

  test "non-owner cannot run task from same organization" do
    task = @reader_activity.tasks.first
    post run_activity_task_url(@reader_activity, task)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to queue this task.", flash[:alert]
  end

  test "should not access tasks when not logged in" do
    delete session_url

    task = @admin_activity.tasks.first
    get activity_task_url(@admin_activity, task)
    assert_redirected_to new_session_path

    post run_activity_task_url(@admin_activity, task)
    assert_redirected_to new_session_path
  end
end
