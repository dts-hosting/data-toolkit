require "test_helper"

class DataItemTest < ActiveSupport::TestCase
  setup do
    @data_item = DataItem.new(
      data: {objectNumber: "123"},
      position: 1,
      activity: create_activity
    )
  end

  test "valid data item" do
    assert @data_item.valid?
  end

  test "requires data" do
    @data_item.data = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:data], "can't be blank"
  end

  test "requires position" do
    @data_item.position = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:position], "can't be blank"
  end

  test "requires activity" do
    @data_item.activity = nil
    refute @data_item.valid?
    assert_includes @data_item.errors[:activity], "must exist"
  end

  test "position must be unique within activity scope" do
    duplicate_item = @data_item.dup
    @data_item.save!
    refute duplicate_item.valid?
    assert_includes duplicate_item.errors[:position], "has already been taken"
  end
end
