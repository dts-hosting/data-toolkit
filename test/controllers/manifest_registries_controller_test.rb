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
end
