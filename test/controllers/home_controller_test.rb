require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when authenticated" do
    sign_in(users(:admin))
    get home_index_url
    assert_response :success
    # TODO: add assertions about content/behavior
    # assert_select "h1", "Welcome to Data Toolkit"
  end

  test "should redirect to login when not authenticated" do
    get home_index_url
    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
