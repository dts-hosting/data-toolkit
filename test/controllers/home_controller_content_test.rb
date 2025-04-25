require "test_helper"

class HomeControllerContentTest < ActionDispatch::IntegrationTest
  setup do
    @admin = sign_in(users(:admin))
    @reader = users(:reader)
    @external = users(:external)

    data_config = create_data_config_record_type

    3.times do
      create_activity(user: @admin, data_config: data_config)
    end

    3.times do
      create_activity(user: @reader, data_config: data_config)
    end

    3.times do
      create_activity(user: @external, data_config: data_config)
    end
  end

  test "should get group_activities with activities from same cspace_url" do
    get group_activities_url
    assert_response :success

    assert_select "##{dom_id(@admin.activities.first)}", count: 0

    assert_select "##{dom_id(@reader.activities.first)}"
    assert_select "##{dom_id(@reader.activities.last)}"

    assert_select "##{dom_id(@external.activities.first)}", count: 0
  end

  test "should get my_activities with only current user's activities" do
    get my_activities_url
    assert_response :success

    assert_select "##{dom_id(@admin.activities.first)}"
    assert_select "##{dom_id(@admin.activities.last)}"

    assert_select "##{dom_id(@reader.activities.first)}", count: 0
    assert_select "##{dom_id(@external.activities.first)}", count: 0
  end
end
