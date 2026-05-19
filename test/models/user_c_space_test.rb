require "test_helper"

class UserCSpaceTest < ActiveSupport::TestCase
  test "requires cspace_api_version" do
    user = User.new(valid_user_attributes.merge(cspace_api_version: nil))
    assert_not user.valid?
    assert_includes user.errors[:cspace_api_version], "can't be blank"
  end

  test "requires cspace_profile" do
    user = User.new(valid_user_attributes.merge(cspace_profile: nil))
    assert_not user.valid?
    assert_includes user.errors[:cspace_profile], "can't be blank"
  end

  test "requires cspace_ui_version" do
    user = User.new(valid_user_attributes.merge(cspace_ui_version: nil))
    assert_not user.valid?
    assert_includes user.errors[:cspace_ui_version], "can't be blank"
  end

  test "profile version override must be set as a pair" do
    user = User.new(valid_user_attributes.merge(
      cspace_profile_override: "anthro",
      cspace_ui_version_override: nil
    ))

    assert_not user.valid?
    assert_includes user.errors[:base], "Profile and UI version override must be set together"
  end

  test "effective profile and version use override when present" do
    user = User.new(valid_user_attributes.merge(
      cspace_profile: "core",
      cspace_ui_version: "1.0",
      cspace_profile_override: "anthro",
      cspace_ui_version_override: "8.2"
    ))

    assert_equal "anthro", user.effective_cspace_profile
    assert_equal "8.2", user.effective_cspace_ui_version
    assert user.cspace_profile_version_overridden?
  end

  test "effective profile and version fall back to detected values" do
    user = User.new(valid_user_attributes.merge(
      cspace_profile: "core",
      cspace_ui_version: "1.0"
    ))

    assert_equal "core", user.effective_cspace_profile
    assert_equal "1.0", user.effective_cspace_ui_version
    assert_not user.cspace_profile_version_overridden?
  end

  test "cspace_url must be present" do
    user = User.new(valid_user_attributes.merge(cspace_url: nil))
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "can't be blank"
  end

  test "cspace_url must be a valid URL" do
    user = User.new(valid_user_attributes.merge(cspace_url: "invalid-url"))
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "must be a valid URL ending with /cspace-services"
  end

  test "cspace_url maximum length" do
    user = User.new(valid_user_attributes.merge(cspace_url: "https://#{"a" * 2050}.com"))
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "is too long (maximum is 2048 characters)"
  end
end
