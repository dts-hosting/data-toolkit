require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email_address is required" do
    user = User.new(
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique within same cspace_url" do
    existing_user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )

    user = User.new(
      email_address: "test@example.com",
      password: "different_password",
      cspace_url: existing_user.cspace_url,
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "email_address normalization" do
    user = User.new(
      email_address: "  Test@EXAMPLE.com  ",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    user.valid?
    assert_equal "test@example.com", user.email_address
  end

  test "requires cspace_api_version" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?

    user.cspace_api_version = nil
    assert_not user.valid?
    assert_includes user.errors[:cspace_api_version], "can't be blank"
  end

  test "requires cspace_profile" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:cspace_profile], "can't be blank"
  end

  test "requires cspace_ui_version" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core"
    )
    assert_not user.valid?
    assert_includes user.errors[:cspace_ui_version], "can't be blank"
  end

  test "cspace_url must be present" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "can't be blank"
  end

  test "cspace_url must be a valid URL" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "not-a-url",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "must be a valid URL"
  end

  test "cspace_url formatting" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    user.save
    assert_match %r{/cspace-services$}, user.cspace_url
  end

  test "password is required" do
    user = User.new(
      email_address: "test@example.com",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "destroying user destroys associated sessions" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "7.0.0",
      cspace_profile: "core",
      cspace_ui_version: "7.0.0"
    )
    user.sessions.create!

    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
