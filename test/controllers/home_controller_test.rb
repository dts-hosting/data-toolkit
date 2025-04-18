require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when authenticated" do
    sign_in(users(:admin))
    get root_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    get root_url
    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
