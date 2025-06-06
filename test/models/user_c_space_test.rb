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
