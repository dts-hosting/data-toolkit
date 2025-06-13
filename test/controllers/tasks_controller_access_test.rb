require "test_helper"

class TasksControllerAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @reader = users(:reader)
    @external_user = users(:external)

    @data_config = create_data_config_record_type(record_type: "media")

    sign_in(@admin)

    @admin_activity = create_activity(
      type: "Activities::CheckMediaDerivatives", user: @admin, data_config: @data_config
    )
    @reader_activity = create_activity(
      type: "Activities::CheckMediaDerivatives", user: @reader, data_config: @data_config
    )
    @external_activity = create_activity(
      type: "Activities::CheckMediaDerivatives", user: @external_user, data_config: @data_config
    )

    @admin_task = @admin_activity.tasks.first
    @reader_task = @reader_activity.tasks.first
    @external_task = @external_activity.tasks.first
  end

  test "should show user's own task" do
    get activity_task_url(@admin_activity, @admin_task)
    assert_response :success

    assert_select "h5", /#{@admin_task.class.display_name}/
  end

  test "should show task from same organization" do
    get activity_task_url(@reader_activity, @reader_task)
    assert_response :success

    assert_select "h5", /#{@reader_task.class.display_name}/
  end

  test "should not show task from different organization" do
    get activity_task_url(@external_activity, @external_task)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not show task that doesn't exist" do
    get activity_task_url(@admin_activity, 999)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not access task with mismatched activity" do
    get activity_task_url(@reader_activity, @admin_task)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not access tasks when not logged in" do
    delete session_url

    get activity_task_url(@admin_activity, @admin_task)
    assert_redirected_to new_session_path
  end

  test "owner should be able to run their own task" do
    @admin_task.update!(status: "pending", started_at: nil)
    post run_activity_task_url(@admin_activity, @admin_task)

    assert_redirected_to activity_path(@admin_activity)
    assert_equal "Task was successfully queued.", flash[:notice]

    @admin_task.reload
    assert_equal "queued", @admin_task.status
  end

  test "user from same organization cannot run another user's task" do
    @reader_task.update!(status: "pending", started_at: nil)
    post run_activity_task_url(@reader_activity, @reader_task)

    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to queue this task.", flash[:alert]

    assert_equal "pending", @reader_task.status
  end

  test "user from different organization cannot run task" do
    post run_activity_task_url(@external_activity, @external_task)

    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this task.", flash[:alert]
  end

  test "should not run task when not logged in" do
    delete session_url

    post run_activity_task_url(@admin_activity, @admin_task)
    assert_redirected_to new_session_path
  end
end
