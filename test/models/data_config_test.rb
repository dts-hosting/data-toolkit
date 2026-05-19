require "test_helper"

class DataConfigTest < ActiveSupport::TestCase
  def setup
    # these are not saved to the db, we use them for validations
    @record_type_config = DataConfig.new(
      manifest: manifests(:v1),
      config_type: "record_type",
      profile: "core",
      record_type: "collectionobject",
      url: "https://example.com/core-collectionobject-1.0.0.json",
      version: "1.0.0"
    )

    @term_list_config = DataConfig.new(
      manifest: manifests(:v1),
      config_type: "term_list",
      profile: "core",
      url: "https://example.com/core-vocbalaries-1.0.0.json",
      version: "1.0.0"
    )

    @optlist_config = DataConfig.new(
      manifest: manifests(:v1),
      config_type: "optlist_override",
      profile: "core",
      url: "https://example.com/core-optlist.json"
    )
  end

  # Validation Tests
  test "valid record_type config" do
    assert @record_type_config.valid?
  end

  test "valid term_list config" do
    assert @term_list_config.valid?
  end

  test "valid optlist_override config" do
    assert @optlist_config.valid?
  end

  test "invalid without config_type" do
    @record_type_config.config_type = nil
    assert_not @record_type_config.valid?
  end

  test "invalid with wrong config_type" do
    assert_raises ArgumentError do
      @record_type_config.config_type = "invalid_type"
    end
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

  test "record_type not required and unsupported for term_list config" do
    @term_list_config.record_type = nil
    assert @term_list_config.valid?

    @term_list_config.record_type = "collectionobject"
    assert_not @term_list_config.valid?
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

  test "record_type not required and unsupported for optlist_override config" do
    @optlist_config.record_type = nil
    assert @optlist_config.valid?

    @optlist_config.record_type = "collectionobject"
    assert_not @optlist_config.valid?
  end

  test "version not required and unsupported for optlist_override config" do
    @optlist_config.version = nil
    assert @optlist_config.valid?

    @optlist_config.version = "1.0.0"
    assert_not @optlist_config.valid?
  end

  test "uniqueness validation for different config types" do
    base_url = "https://example.com/config"
    profile_name = "test_profile"
    version_value = "1.0"
    record_type_value = "object"

    # Test for record_type config (requires config_type, profile, version, record_type)
    opts = {
      manifest: manifests(:v1),
      config_type: "record_type",
      profile: profile_name,
      version: version_value,
      record_type: record_type_value,
      url: base_url
    }
    DataConfig.create!(opts)

    duplicate_record = DataConfig.new(opts)
    assert_not duplicate_record.valid?
    assert_includes duplicate_record.errors[:data_config], "this set of attributes already exists"

    different_record = DataConfig.new(opts.merge(record_type: "different_record_type"))
    assert different_record.valid?

    # Test for term_list config (requires config_type, profile, version)
    opts = {
      manifest: manifests(:v1),
      config_type: "term_list",
      profile: profile_name,
      version: version_value,
      url: base_url
    }
    DataConfig.create!(opts)

    duplicate_term_list = DataConfig.new(opts)

    assert_not duplicate_term_list.valid?
    assert_includes duplicate_term_list.errors[:data_config], "this set of attributes already exists"

    different_version_term_list = DataConfig.new(opts.merge(version: "2.0"))
    assert different_version_term_list.valid?

    # Test for optlist_override config (requires config_type, profile)
    opts = {
      manifest: manifests(:v1),
      config_type: "optlist_override",
      profile: profile_name,
      url: base_url
    }
    DataConfig.create!(opts)

    duplicate_optlist = DataConfig.new(opts)
    assert_not duplicate_optlist.valid?
    assert_includes duplicate_optlist.errors[:data_config], "this set of attributes already exists"

    different_profile_optlist = DataConfig.new(opts.merge(profile: "different_profile"))
    assert different_profile_optlist.valid?
  end

  # Scope Tests
  test "optlist_override scope" do
    @optlist_config.save!
    assert_includes DataConfig.optlist_override(users(:admin)), @optlist_config
    assert_not_includes DataConfig.optlist_override(users(:admin)), @record_type_config
  end

  test "record_type scope" do
    @record_type_config.save!
    assert_includes DataConfig.record_type(users(:admin)), @record_type_config
    assert_not_includes DataConfig.record_type(users(:admin)), @optlist_config
  end

  test "record_type scope uses user's effective profile and version" do
    user = users(:admin)
    user.update!(
      cspace_profile_override: "anthro",
      cspace_ui_version_override: "8.2.0"
    )
    override_config = create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "collectionobject",
      url: "https://example.com/anthro-collectionobject-8.2.0.json"
    )
    detected_config = create_data_config_record_type(
      profile: user.cspace_profile,
      version: user.cspace_ui_version,
      record_type: "acquisitions",
      url: "https://example.com/core-acquisitions-1.0.0.json"
    )

    scope = DataConfig.record_type(user)

    assert_includes scope, override_config
    assert_not_includes scope, detected_config
  end

  test "profile_version_options returns distinct pairs from supported config types" do
    first = create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "collectionobject",
      url: "https://example.com/anthro-collectionobject-8.2.0.json"
    )
    create_data_config_record_type(
      profile: "anthro",
      version: "8.2.0",
      record_type: "media",
      url: "https://example.com/anthro-media-8.2.0.json"
    )
    create_data_config_term_list(
      profile: "core",
      version: "1.0.0",
      url: "https://example.com/core-vocabularies-1.0.0.json"
    )
    create_data_config_optlist_override(
      profile: "media",
      url: "https://example.com/media-optlist.json"
    )

    options = DataConfig.profile_version_options

    assert_equal 1, options.count { |option| option.profile == "anthro" && option.version == "8.2.0" }
    assert_includes options.map(&:id), first.id
    assert_includes options.map(&:display_name), "core 1.0.0"
    assert_not_includes options.map(&:display_name), "media"
  end

  test "profile_version_options sorts by profile ascending and version descending" do
    [
      ["anthro", "9.0.0"],
      ["core", "10.0.0"],
      ["anthro", "9.2.0"],
      ["core", "9.0.0"],
      ["anthro", "9.1.0"]
    ].each do |profile, version|
      create_data_config_record_type(
        profile: profile,
        version: version,
        record_type: "collectionobject-#{profile}-#{version}",
        url: "https://example.com/#{profile}-#{version}.json"
      )
    end

    assert_equal [
      "anthro 9.2.0",
      "anthro 9.1.0",
      "anthro 9.0.0",
      "core 10.0.0",
      "core 9.0.0"
    ], DataConfig.profile_version_options.map(&:display_name)
  end

  test "term_list scope" do
    @term_list_config.save!
    assert_includes DataConfig.term_list(users(:admin)), @term_list_config
    assert_not_includes DataConfig.term_list(users(:admin)), @record_type_config
  end

  test "media_record_type scope matches legacy and human-friendly record_type values case-insensitively" do
    user = users(:admin)
    legacy_media = create_data_config_record_type(
      record_type: "media",
      url: "https://example.com/core-media-1.0.0.json"
    )
    legacy_restricted = create_data_config_record_type(
      record_type: "restrictedmedia",
      url: "https://example.com/core-restrictedmedia-1.0.0.json"
    )
    friendly_media = create_data_config_record_type(
      record_type: "Media Handling",
      url: "https://example.com/core-media-handling-1.0.0.json"
    )
    friendly_restricted = create_data_config_record_type(
      record_type: "Restricted Media Handling",
      url: "https://example.com/core-restricted-media-handling-1.0.0.json"
    )

    scope = DataConfig.media_record_type(user)
    assert_includes scope, legacy_media
    assert_includes scope, legacy_restricted
    assert_includes scope, friendly_media
    assert_includes scope, friendly_restricted

    @record_type_config.save!
    assert_not_includes scope, @record_type_config
  end

  # Helper Method Tests
  test "optlist_override_config?" do
    assert @optlist_config.optlist_override?
    assert_not @record_type_config.optlist_override?
  end

  test "record_type_config?" do
    assert @record_type_config.record_type?
    assert_not @optlist_config.record_type?
  end

  test "term_list_config?" do
    assert @term_list_config.term_list?
    assert_not @record_type_config.term_list?
  end

  # Lookup Data Config Tests
  test "lookup_data_config" do
    user = users(:admin)
    activities = [
      Activity.new(
        user: user,
        data_config: create_data_config_record_type,
        type: :export_record_ids
      )
    ]

    # TODO: handle more cases
    activities.each do |activity|
      assert DataConfig.for(user, activity).any?
    end
  end
end
