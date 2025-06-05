require "test_helper"

class UserAdminTest < ActiveSupport::TestCase
  def setup
    @admin_email = "admin@example.com"
    Rails.configuration.admin_emails = [@admin_email]
  end

  def teardown
    Rails.configuration.admin_emails = ENV.fetch("ADMIN_EMAILS", "").split(",")
  end

  test "admin? returns true for users with emails in admin_emails config" do
    user = User.new(
      email_address: @admin_email,
      cspace_url: "https://example.com/cspace-services",
      cspace_api_version: "1.0",
      cspace_profile: "default",
      cspace_ui_version: "1.0",
      password: "password123"
    )

    assert user.admin?, "User with admin email should be identified as admin"

    regular_user = User.new(
      email_address: "regular@example.com",
      cspace_url: "https://example.com/cspace-services",
      cspace_api_version: "1.0",
      cspace_profile: "default",
      cspace_ui_version: "1.0",
      password: "password123"
    )

    assert_not regular_user.admin?, "User with non-admin email should not be identified as admin"
  end
end
