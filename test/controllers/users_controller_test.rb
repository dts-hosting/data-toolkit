require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "can access own profile" do
    user = users(:reader)
    sign_in(user)
    get user_path(user)
    assert_response :success
  end

  test "cannot access another user's profile" do
    user = users(:reader)
    other_user = users(:admin)

    sign_in(user)
    get user_path(other_user)

    assert_redirected_to root_path
    assert_equal "You are not authorized to access this page", flash[:alert]
  end

  test "admin can access any user's profile" do
    skip "Need to implement admin? for User"

    admin_user = users(:admin)
    other_user = users(:reader)

    sign_in(admin_user)
    get user_path(other_user)

    assert_response :success
  end
end
