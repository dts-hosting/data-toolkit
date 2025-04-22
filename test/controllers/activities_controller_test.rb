require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @reader = users(:reader)
    @external_user = users(:external)

    @data_config = create_data_config_record_type

    sign_in(@admin)

    @admin_activity = create_activity(user: @admin, data_config: @data_config)
    @reader_activity = create_activity(user: @reader, data_config: @data_config)
    @external_activity = create_activity(user: @external_user, data_config: @data_config)
  end

  test "should get new with valid activity type" do
    get new_activity_with_type_url(type: "create-or-update-records")
    assert_response :success

    assert_select "h5", text: /New Create or Update Records/
    assert_select "input[name='activity[type]'][value='Activities::CreateOrUpdateRecords']"
  end

  test "should redirect with invalid activity type" do
    get new_activity_with_type_url(type: "invalid_type")
    assert_redirected_to my_activities_url
    assert_equal "Invalid activity type", flash[:alert]
  end

  test "should create activity with valid attributes" do
    assert_difference("Activity.count") do
      post activities_url, params: {
        activity: {
          type: "Activities::CreateOrUpdateRecords",
          data_config_id: @data_config.id,
          files: [fixture_file_upload(
            Rails.root.join("test/fixtures/files/test.csv"),
            "text/csv"
          )],
          batch_config_attributes: {
            batch_mode: "a"
          }
        }
      }
    end

    created_activity = Activity.last
    assert_equal @admin.id, created_activity.user_id
    assert_redirected_to activity_path(created_activity)
    assert_equal "Create or Update Records was successfully created.", flash[:notice]
  end

  test "should not create activity with invalid attributes" do
    assert_no_difference("Activity.count") do
      post activities_url, params: {
        activity: {
          type: "Activities::CreateOrUpdateRecords",
          data_config_id: nil
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "should show user's own activity" do
    get activity_url(@admin_activity)
    assert_response :success

    assert_select "h5", /#{@admin_activity.class.display_name}/
  end

  test "should show activity from same organization" do
    get activity_url(@reader_activity)
    assert_response :success

    assert_select "h5", /#{@reader_activity.class.display_name}/
  end

  test "should not show activity from different organization" do
    get activity_url(@external_activity)
    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this activity.", flash[:alert]
  end

  test "should destroy user's own activity" do
    assert_difference("Activity.count", -1) do
      delete activity_url(@admin_activity)
    end

    assert_redirected_to activities_path
    assert_equal "Activity was successfully deleted.", flash[:notice]
  end

  test "should not destroy activity that doesn't exist" do
    assert_no_difference("Activity.count") do
      delete activity_url(999)
    end

    assert_redirected_to my_activities_url
    assert_equal "You don't have permission to access this activity.", flash[:alert]
  end

  test "should not access activities when not logged in" do
    delete session_url

    get activity_url(@admin_activity)
    assert_redirected_to new_session_path

    get new_activity_with_type_url(type: "create_or_update_records")
    assert_redirected_to new_session_path

    post activities_url, params: {activity: {type: "Activities::CreateOrUpdateRecords"}}
    assert_redirected_to new_session_path

    delete activity_url(@admin_activity)
    assert_redirected_to new_session_path
  end

  test "should build batch config when activity requires it" do
    get new_activity_with_type_url(type: "create-or-update-records")
    assert_response :success

    assert_select "h6", text: "Batch config"
    assert_select "input[name*='batch_config_attributes']", minimum: 1
  end
end
