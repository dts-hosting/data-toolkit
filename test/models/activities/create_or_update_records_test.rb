require "test_helper"

class CreateOrUpdateRecordsTest < ActiveSupport::TestCase
  def setup
    user = users(:admin)
    data_config = create_data_config_record_type
    files = create_uploaded_files(["test.csv"])
    @activity = Activity.new(
      user: user,
      config: {action: "create"},
      data_config: data_config,
      type: "Activities::CreateOrUpdateRecords",
      label: "Test Label #{SecureRandom.hex(4)}",
      files: files
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
end
