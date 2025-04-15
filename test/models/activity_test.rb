require "test_helper"
# TODO: Activity subclass tests

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @data_config = create_data_config_record_type

    @activity = Activity.new(
      user: @user,
      data_config: @data_config,
      type: "Activities::ExportRecordIds"
    )
  end

  test "should be valid with required attributes" do
    assert @activity.valid?
  end

  test "should require a user" do
    @activity.user = nil
    refute @activity.valid?
    assert_not_nil @activity.errors[:user]
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

  test "should allow file attachments" do
    @activity.files.attach(
      io: StringIO.new("test content"),
      filename: "test.csv",
      content_type: "text/csv"
    )
    assert @activity.files.attached?
  end
end
