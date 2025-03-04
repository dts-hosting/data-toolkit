require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @current_time = Time.current
  end

  test "sweep removes stale sessions" do
    old_updated = Session.create!(
      user: @user,
      updated_at: 3.hours.ago,
      created_at: 1.day.ago
    )

    old_created = Session.create!(
      user: @user,
      updated_at: 1.hour.ago,
      created_at: 2.days.ago
    )

    fresh_session = Session.create!(
      user: @user,
      updated_at: 1.hour.ago,
      created_at: 1.hour.ago
    )

    Session.sweep

    assert_not Session.exists?(old_updated.id)
    assert_not Session.exists?(old_created.id)
    assert Session.exists?(fresh_session.id)
  end

  test "sweep respects custom time threshold" do
    custom_session = Session.create!(
      user: @user,
      updated_at: 45.minutes.ago,
      created_at: 45.minutes.ago
    )

    Session.sweep(30.minutes)

    assert_not Session.exists?(custom_session.id), "Session should be removed with custom threshold"
  end
end
