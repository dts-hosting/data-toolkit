require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_email = users(:admin).email_address
    Rails.configuration.admin_emails = [@admin_email]
  end

  teardown do
    Rails.configuration.admin_emails = ENV.fetch("ADMIN_EMAILS", "").split(",")
  end

  test "can access own profile" do
    user = users(:reader)
    sign_in(user)
    get user_path(user)
    assert_response :success

    assert_select "div", text: /Detected profile/
    assert_select "div", text: /Active profile/
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
    admin_user = users(:admin)
    other_user = users(:reader)

    sign_in(admin_user)
    get user_path(other_user)

    assert_response :success
  end

  test "user can set own profile version override" do
    user = users(:reader)
    data_config = create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "collectionobject",
      url: "https://example.com/anthro-collectionobject-8.2.0.json"
    )

    sign_in(user)
    patch user_path(user), params: {
      user: {
        profile_version_data_config_id: data_config.id
      }
    }

    assert_redirected_to user_path(user)
    assert_equal "Profile/version override was updated.", flash[:notice]

    user.reload
    assert_equal "anthro", user.cspace_profile_override
    assert_equal "8.2.0", user.cspace_ui_version_override
  end

  test "admin can set another user's profile version override" do
    admin_user = users(:admin)
    other_user = users(:reader)
    data_config = create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "collectionobject",
      url: "https://example.com/anthro-collectionobject-8.2.0.json"
    )

    sign_in(admin_user)
    patch user_path(other_user), params: {
      user: {
        profile_version_data_config_id: data_config.id
      }
    }

    assert_redirected_to user_path(other_user)
    other_user.reload
    assert_equal "anthro", other_user.cspace_profile_override
    assert_equal "8.2.0", other_user.cspace_ui_version_override
  end

  test "cannot set another user's profile version override without admin access" do
    user = users(:reader)
    other_user = users(:admin)
    data_config = create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "collectionobject",
      url: "https://example.com/anthro-collectionobject-8.2.0.json"
    )

    sign_in(user)
    patch user_path(other_user), params: {
      user: {
        profile_version_data_config_id: data_config.id
      }
    }

    assert_redirected_to root_path
    assert_nil other_user.reload.cspace_profile_override
  end

  test "user can set override from term list data config" do
    user = users(:reader)
    data_config = create_data_config_term_list(
      profile: "anthro",
      version: "8.2.0",
      url: "https://example.com/anthro-vocabularies-8.2.0.json"
    )

    sign_in(user)
    patch user_path(user), params: {
      user: {
        profile_version_data_config_id: data_config.id
      }
    }

    assert_redirected_to user_path(user)
    user.reload
    assert_equal "anthro", user.cspace_profile_override
    assert_equal "8.2.0", user.cspace_ui_version_override
  end

  test "cannot set override from optlist override data config" do
    user = users(:reader)
    data_config = create_data_config_optlist_override(
      profile: "anthro",
      url: "https://example.com/anthro-optlist.json"
    )

    sign_in(user)
    patch user_path(user), params: {
      user: {
        profile_version_data_config_id: data_config.id
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, "Select a supported profile and UI version"
    assert_nil user.reload.cspace_profile_override
  end

  test "user can remove own profile version override" do
    user = users(:reader)
    user.update!(
      cspace_profile_override: "anthro",
      cspace_ui_version_override: "8.2.0"
    )

    sign_in(user)
    delete reset_user_path(user)

    assert_redirected_to user_path(user)
    assert_equal "Profile/version override was removed.", flash[:notice]
    assert_nil user.reload.cspace_profile_override
    assert_nil user.cspace_ui_version_override
  end
end
