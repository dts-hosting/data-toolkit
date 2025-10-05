require "test_helper"

class CreateOrUpdateRecordsTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type
    @files = create_uploaded_files(["test.csv"])
    @activity = Activity.new(
      user: @user,
      config: {action: "create"},
      data_config: @data_config,
      type: "Activities::CreateOrUpdateRecords",
      label: "Test Label #{SecureRandom.hex(4)}",
      files: @files
    )
    @activity.build_batch_config
    @activity.save!
  end

  test "should be valid with required attributes" do
    assert @activity.valid?
  end

  test "should require a user" do
    @activity.user = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:user]
  end

  test "should require a config" do
    @activity.config = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:config]
  end

  test "should require a data_config" do
    @activity.data_config = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:data_config]
  end

  test "should require a type" do
    @activity.type = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:type]
  end

  test "should allow only one file attachments" do
    @activity.files.attach(
      io: StringIO.new("test content"),
      filename: "additional.csv",
      content_type: "text/csv"
    )
    refute @activity.valid?
  end

  test "sets action to create and auto_advance to true by default" do
    activity = Activities::CreateOrUpdateRecords.new(
      user: @user,
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}",
      files: @files
    )
    activity.build_batch_config

    assert_equal "create", activity.config["action"]
    assert_equal true, activity.config["auto_advance"]
    activity.save
    assert_equal "create", activity.reload.config["action"]
    assert_equal true, activity.reload.config["auto_advance"]
  end

  test "preserves custom action value" do
    activity = Activities::CreateOrUpdateRecords.new(
      user: @user,
      config: {action: "update"},
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}",
      files: @files
    )
    activity.build_batch_config

    assert_equal "update", activity.config["action"]
    assert_equal true, activity.config["auto_advance"]
    activity.save
    assert_equal "update", activity.reload.config["action"]
    assert_equal true, activity.reload.config["auto_advance"]
  end

  test "preserves custom action, key and auto_advance values" do
    activity = Activities::CreateOrUpdateRecords.new(
      user: @user,
      config: {action: "update", auto_advance: false, custom_key: "custom_value"},
      data_config: @data_config,
      label: "Test #{SecureRandom.hex(4)}",
      files: @files
    )
    activity.build_batch_config

    assert_equal "update", activity.config["action"]
    assert_equal false, activity.config["auto_advance"]
    assert_equal "custom_value", activity.config["custom_key"]
    activity.save
    assert_equal "update", activity.reload.config["action"]
    assert_equal false, activity.reload.config["auto_advance"]
    assert_equal "custom_value", activity.reload.config["custom_key"]
  end
end
