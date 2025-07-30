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
end
