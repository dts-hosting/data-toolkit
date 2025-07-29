require "test_helper"

class ManifestRegistriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = sign_in(users(:admin))
    @manifest_registry = ManifestRegistry.create!(
      url: "https://example.com/registry.json"
    )
  end

  test "should get index" do
    get manifest_registries_url
    assert_response :success
    assert_select "h5", "Manifest Registries"
    assert_select "form[action=?]", manifest_registries_path
  end

  test "should show manifest_registry" do
    get manifest_registry_url(@manifest_registry)
    assert_response :success
    assert_select "h5", "Registry Information"
  end

  test "should create manifest_registry" do
    assert_difference("ManifestRegistry.count") do
      post manifest_registries_url, params: {
        manifest_registry: {url: "https://example.com/new-registry.json"}
      }
    end

    assert_redirected_to manifest_registries_url
    assert_equal "Manifest registry was successfully created.", flash[:notice]
  end

  test "should render index with errors when create fails" do
    assert_no_difference("ManifestRegistry.count") do
      post manifest_registries_url, params: {
        manifest_registry: {url: ""}
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "should not create duplicate manifest_registry" do
    assert_no_difference("ManifestRegistry.count") do
      post manifest_registries_url, params: {
        manifest_registry: {url: @manifest_registry.url}
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "should destroy manifest registry when safe to delete" do
    @manifest_registry.manifests.create!(url: "https://example.com/test-manifest")
    create_data_config_record_type(manifest: @manifest_registry.manifests.first)

    assert @manifest_registry.safe_to_delete?

    assert_difference("ManifestRegistry.count", -1) do
      delete manifest_registry_url(@manifest_registry)
    end

    assert_redirected_to manifest_registries_path
    assert_equal "Manifest registry was successfully deleted.", flash[:notice]
  end

  test "should not destroy manifest registry when data configs are in use" do
    @manifest_registry.manifests.create!(url: "https://example.com/test-manifest")
    data_config = create_data_config_record_type(manifest: @manifest_registry.manifests.first)
    create_activity(data_config: data_config)

    assert_not @manifest_registry.safe_to_delete?

    assert_no_difference("ManifestRegistry.count") do
      delete manifest_registry_path(@manifest_registry)
    end

    assert_redirected_to manifest_registries_path
    assert_equal "Cannot delete manifest registry because it contains data configs that are currently in use.", flash[:alert]
  end

  test "should handle non-existent manifest registry" do
    assert_no_difference("ManifestRegistry.count") do
      delete manifest_registry_url(id: 999999)
    end

    assert_response :not_found
  end

  test "should run manifest registry import job" do
    assert_enqueued_with(job: ManifestRegistryImportJob) do
      post run_manifest_registry_url(@manifest_registry)
    end

    assert_redirected_to manifest_registries_path
    assert_equal "Registry import job has been queued.", flash[:notice]
  end
end
