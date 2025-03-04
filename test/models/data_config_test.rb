require "test_helper"

class DataConfigTest < ActiveSupport::TestCase
  def setup
    # these are not saved to the db, we use them for validations
    @record_type_config = DataConfig.new(
      config_type: "record_type",
      profile: "core",
      record_type: "collectionobject",
      url: "https://example.com/core-collectionobject-7.0.0.json",
      version: "7.0.0"
    )

    @term_lists_config = DataConfig.new(
      config_type: "term_lists",
      profile: "core",
      url: "https://example.com/core-vocbalaries-7.0.0.json",
      version: "7.0.0"
    )

    @optlist_config = DataConfig.new(
      config_type: "optlist_overrides",
      profile: "core",
      url: "https://example.com/core-optlist.json"
    )
  end

  # Validation Tests
  test "valid record_type config" do
    assert @record_type_config.valid?
  end

  test "valid term_lists config" do
    assert @term_lists_config.valid?
  end

  test "valid optlist_overrides config" do
    assert @optlist_config.valid?
  end

  test "invalid without config_type" do
    @record_type_config.config_type = nil
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:config_type], "can't be blank"
  end

  test "invalid with wrong config_type" do
    @record_type_config.config_type = "invalid_type"
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:config_type], "is not included in the list"
  end

  test "invalid without profile" do
    @record_type_config.profile = nil
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:profile], "can't be blank"
  end

  test "record_type required for record_type config" do
    @record_type_config.record_type = nil
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:record_type], "can't be blank"
  end

  test "record_type not required for term_lists config" do
    @term_lists_config.record_type = nil
    assert @term_lists_config.valid?
  end

  test "invalid without url" do
    @record_type_config.url = nil
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:url], "can't be blank"
  end

  test "invalid with malformed url" do
    @record_type_config.url = "not-a-url"
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:url], "is invalid"
  end

  test "version required for record_type config" do
    @record_type_config.version = nil
    assert_not @record_type_config.valid?
    assert_includes @record_type_config.errors[:version], "can't be blank"
  end

  test "version not required for optlist_overrides config" do
    @optlist_config.version = nil
    assert @optlist_config.valid?
  end

  # Scope Tests
  test "optlist_overrides scope" do
    @optlist_config.save!
    assert_includes DataConfig.optlist_overrides(users(:admin)), @optlist_config
    assert_not_includes DataConfig.optlist_overrides(users(:admin)), @record_type_config
  end

  test "record_type scope" do
    @record_type_config.save!
    assert_includes DataConfig.record_type(users(:admin)), @record_type_config
    assert_not_includes DataConfig.record_type(users(:admin)), @optlist_config
  end

  test "term_lists scope" do
    @term_lists_config.save!
    assert_includes DataConfig.term_lists(users(:admin)), @term_lists_config
    assert_not_includes DataConfig.term_lists(users(:admin)), @record_type_config
  end

  # Helper Method Tests
  test "optlist_overrides_config?" do
    assert @optlist_config.optlist_overrides_config?
    assert_not @record_type_config.optlist_overrides_config?
  end

  test "record_type_config?" do
    assert @record_type_config.record_type_config?
    assert_not @optlist_config.record_type_config?
  end

  test "term_lists_config?" do
    assert @term_lists_config.term_lists_config?
    assert_not @record_type_config.term_lists_config?
  end

  # Lookup Data Config Tests
  test "lookup_data_config" do
    user = users(:admin)
    activities = [
      Activity.new(
        user: user,
        data_config: create_data_config_record_type,
        type: "Activities::ExportRecordId"
      )
    ]

    # TODO: handle more cases

    activities.each do |activity|
      assert DataConfig.for(user, activity).any?
    end
  end
end
