require "test_helper"

class ActivityConfigTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type
  end

  test "Activity sets auto_advance to true by default" do
    activity = Activities::ExportRecordIds.new(
      user: @user,
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}"
    )

    assert_equal true, activity.config["auto_advance"]
    activity.save
    assert_equal true, activity.reload.config["auto_advance"]
  end

  test "Activity preserves custom auto_advance value" do
    activity = Activities::ExportRecordIds.new(
      user: @user,
      config: {auto_advance: false},
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}"
    )

    assert_equal false, activity.config["auto_advance"]
    activity.save
    assert_equal false, activity.reload.config["auto_advance"]
  end

  test "Activity preserves additional custom config values" do
    activity = Activities::ExportRecordIds.new(
      user: @user,
      config: {auto_advance: false, custom_key: "custom_value"},
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}"
    )

    assert_equal false, activity.config["auto_advance"]
    assert_equal "custom_value", activity.config["custom_key"]
    activity.save
    assert_equal false, activity.reload.config["auto_advance"]
    assert_equal "custom_value", activity.reload.config["custom_key"]
  end
end
