require "test_helper"

class ManifestRegistryTest < ActiveSupport::TestCase
  def setup
    @manifest_registry = ManifestRegistry.create!(
      url: "https://example.com/registry.json"
    )
  end

  test "safe_to_delete? returns true when no manifests or data configs" do
    @manifest_registry.manifests.create!(url: "https://example.com/test-manifest")

    assert @manifest_registry.safe_to_delete?
  end

  test "safe_to_delete? returns false when manifests or data configs exist" do
    @manifest_registry.manifests.create!(url: "https://example.com/test-manifest")
    data_config = create_data_config_record_type(manifest: @manifest_registry.manifests.first)
    create_activity(data_config: data_config)

    assert_not @manifest_registry.safe_to_delete?
  end

  test "should_process? returns true when incoming timestamp is later on the same day" do
    @manifest_registry.update!(last_updated_at: Time.zone.parse("2026-02-10T10:00:00Z"))

    assert @manifest_registry.send(:should_process?, "2026-02-10T12:00:00Z")
  end

  test "should_process? returns false when incoming timestamp is earlier on the same day" do
    @manifest_registry.update!(last_updated_at: Time.zone.parse("2026-02-10T12:00:00Z"))

    assert_not @manifest_registry.send(:should_process?, "2026-02-10T10:00:00Z")
  end

  test "should_process? returns true when incoming timestamp is invalid" do
    @manifest_registry.update!(last_updated_at: Time.zone.parse("2026-02-10T12:00:00Z"))

    assert @manifest_registry.send(:should_process?, "not-a-timestamp")
  end
end
