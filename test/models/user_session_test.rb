require "test_helper"

class UserSessionTest < ActiveSupport::TestCase
  test "destroying user destroys associated sessions" do
    user = User.create!(valid_user_attributes)
    Session.create!(user: user)

    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
