require "test_helper"
require "ostruct"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @client = setup_mock_client
  end

  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should create session with valid credentials" do
    setup_successful_auth

    post session_url, params: auth_params(@user)

    assert_redirected_to root_path
  end

  test "should fail to create session with invalid credentials" do
    sign_in_with_failed_auth(@user)
    assert_redirected_to new_session_path
    assert_equal "Failed to authenticate with CollectionSpace.", flash[:alert]
  end

  test "should destroy session" do
    setup_successful_auth
    delete session_url
    assert_redirected_to new_session_path
    assert_nil session[:user_id]
  end

  test "should update existing user password if changed" do
    setup_successful_auth
    new_password = "newpassword123"

    post session_url, params: auth_params(@user, password: new_password)

    @user.reload
    assert_equal new_password, @user.password
    assert_redirected_to root_path
  end

  test "should handle version fetch failure" do
    setup_successful_auth(version_data: mock_empty_version_data)
    user = User.new(
      cspace_url: "https://core.dev.collectionspace.org/cspace-services",
      email_address: "<EMAIL>",
      password: "<PASSWORD>"
    )

    post session_url, params: auth_params(user)

    assert_redirected_to new_session_path
    assert_equal "Failed to access version information from CollectionSpace.", flash[:alert]
  end

  test "associates optlist_overrides DataConfig with User" do
    oo = create_data_config_optlist_overrides({profile: "tenantname"})
    user = users(:hostedtenantuser)
    @client = setup_mock_tenant_client
    setup_successful_auth
    post session_url, params: auth_params(user)
    user.reload

    assert_equal oo.id, user.data_config_id
  end

  private

  def setup_mock_client
    client = CollectionSpace::Client.new(
      CollectionSpace::Configuration.new(
        base_uri: "https://core.dev.collectionspace.org/cspace-services",
        username: "admin@core.collectionspace.org",
        password: "Administrator"
      )
    )
    CollectionSpaceApi.stubs(:client_for).returns(client)
    client
  end

  def setup_mock_tenant_client
    client = CollectionSpace::Client.new(
      CollectionSpace::Configuration.new(
        base_uri: "https://tenantname.collectionspace.org/cspace-services",
        username: "admin@core.collectionspace.org",
        password: "Administrator"
      )
    )
    CollectionSpaceApi.stubs(:client_for).returns(client)
    client
  end

  def setup_successful_auth(version_data: mock_version_data)
    @client.stubs(:can_authenticate?).returns(true)
    @client.stubs(:version).returns(version_data)
  end

  def auth_params(user, password: user.password)
    {
      cspace_url: user.cspace_url,
      email_address: user.email_address,
      password: password
    }
  end

  def mock_version_data
    OpenStruct.new(
      api: OpenStruct.new(joined: "7.1.0"),
      ui: OpenStruct.new(
        profile: "core",
        version: "7.1.0"
      )
    )
  end

  def mock_empty_version_data
    OpenStruct.new(
      api: OpenStruct.new(joined: nil),
      ui: OpenStruct.new(
        profile: nil,
        version: nil
      )
    )
  end
end
