require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to login when not authenticated" do
    get home_index_url
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "should get the home page when authenticated" do
    user = create_user(
      cspace_url: "https://core.dev.collectionspace.org",
      email_address: "admin@core.collectionspace.org",
      password: "Administrator"
    )
    sign_in(user)
    get home_index_url
    assert_response :success
  end
end
