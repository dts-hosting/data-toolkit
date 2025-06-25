require "test_helper"

class JobsAccessControllerTest < ActionDispatch::IntegrationTest
  test "non-admin users should be redirected from jobs dashboard" do
    sign_in(users(:reader))

    get "/jobs"
    assert_response :redirect
    refute_equal :success, response.status
  end

  test "admin users should have access to jobs dashboard" do
    sign_in(users(:admin))

    get "/jobs"
    assert_response :success
  end
end
