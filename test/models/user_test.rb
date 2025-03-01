require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email_address is required" do
    user = User.new(valid_user_attributes.merge(email_address: nil))
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique within same cspace_url" do
    User.create!(valid_user_attributes)
    user = User.new(valid_user_attributes)

    assert user.valid?
    assert_raises(ActiveRecord::RecordNotUnique) do
      user.save(validate: false)
    end

    user = User.new(valid_user_attributes.merge(
      cspace_url: "https://different-instance.collectivecare.org"
    ))
    assert user.save
  end

  test "email_address normalization" do
    user = User.new(valid_user_attributes.merge(email_address: " USER@EXAMPLE.COM "))
    user.valid?
    assert_equal "user@example.com", user.email_address
  end

  test "email_address format validation" do
    user = User.new(valid_user_attributes.merge(email_address: "invalid-email"))
    assert_not user.valid?
    assert_includes user.errors[:email_address], "must be a valid email address"
  end

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
    assert_includes user.errors[:cspace_url], "must be a valid URL"
  end

  test "cspace_url maximum length" do
    user = User.new(valid_user_attributes.merge(cspace_url: "https://#{"a" * 2050}.com"))
    assert_not user.valid?
    assert_includes user.errors[:cspace_url], "is too long (maximum is 2048 characters)"
  end

  test "cspace_url formatting" do
    user = User.new(valid_user_attributes.merge(cspace_url: "http://example.com/"))
    user.save!
    assert_equal "http://example.com/cspace-services", user.cspace_url
  end

  test "password is required" do
    user = User.new(valid_user_attributes.merge(password: nil))
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "password minimum length" do
    user = User.new(valid_user_attributes.merge(password: "short"))
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "destroying user destroys associated sessions" do
    user = User.create!(valid_user_attributes)
    Session.create!(user: user)

    assert_difference "Session.count", -1 do
      user.destroy
    end
  end

  private

  def valid_user_attributes
    {
      email_address: "user@example.com",
      password: "password123",
      cspace_url: "https://core.collectionspace.org",
      cspace_api_version: "1.0",
      cspace_profile: "core",
      cspace_ui_version: "1.0"
    }
  end
end
