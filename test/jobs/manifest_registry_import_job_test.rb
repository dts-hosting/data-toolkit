require "test_helper"

class ManifestRegistryImportJobTest < ActiveJob::TestCase
  test "imports only the provided registry" do
    registry = ManifestRegistry.create!(url: "https://example.com/registry-only.json")
    other_registry = ManifestRegistry.create!(url: "https://example.com/registry-other.json")
    manifest = mock("manifest")
    manifest.stubs(:url).returns("https://example.com/manifest-only.json")
    manifest.expects(:import).once

    registry.expects(:import).once.yields(manifest)
    other_registry.expects(:import).never
    ManifestRegistry.expects(:find_each).never

    ManifestRegistryImportJob.perform_now(registry)
  end

  test "imports all registries when no argument is provided" do
    first_registry = ManifestRegistry.create!(url: "https://example.com/registry-first.json")
    second_registry = ManifestRegistry.create!(url: "https://example.com/registry-second.json")
    first_manifest = mock("first_manifest")
    second_manifest = mock("second_manifest")
    first_manifest.stubs(:url).returns("https://example.com/manifest-first.json")
    second_manifest.stubs(:url).returns("https://example.com/manifest-second.json")
    first_manifest.expects(:import).once
    second_manifest.expects(:import).once

    first_registry.expects(:import).once.yields(first_manifest)
    second_registry.expects(:import).once.yields(second_manifest)

    ManifestRegistry.stub(:find_each, ->(&block) { [first_registry, second_registry].each { |registry| block.call(registry) } }) do
      ManifestRegistryImportJob.perform_now
    end
  end
end
