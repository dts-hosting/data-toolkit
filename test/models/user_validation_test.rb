require "test_helper"

class UserValidationTest < ActiveSupport::TestCase
  test "email_address is required" do
    user = User.new(valid_user_attributes.merge(email_address: nil))
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique within same cspace_url" do
    User.create!(valid_user_attributes)
    user = User.new(valid_user_attributes)

    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"

    user = User.new(valid_user_attributes.merge(
      cspace_url: "https://different-instance.collectivecare.org/cspace-services"
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
end
