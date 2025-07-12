require "test_helper"

class ManifestRegistriesAccessControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manifest_registry = ManifestRegistry.create!(
      url: "https://example.com/registry.json"
    )
  end

  test "unauthenticated users should be redirected from index" do
    get manifest_registries_url
    assert_redirected_to new_session_path
  end

  test "unauthenticated users should be redirected from show" do
    get manifest_registry_url(@manifest_registry)
    assert_redirected_to new_session_path
  end

  test "unauthenticated users should be redirected from create" do
    assert_no_difference("ManifestRegistry.count") do
      post manifest_registries_url, params: {
        manifest_registry: {url: "https://example.com/new-registry.json"}
      }
    end
    assert_redirected_to new_session_path
  end

  test "unauthenticated users should be redirected from destroy" do
    assert_no_difference("ManifestRegistry.count") do
      delete manifest_registry_url(@manifest_registry)
    end
    assert_redirected_to new_session_path
  end

  test "unauthenticated users should be redirected from run" do
    assert_no_difference "enqueued_jobs.size" do
      post run_manifest_registry_url(@manifest_registry)
    end
    assert_redirected_to new_session_path
  end

  test "non-admin users should be redirected from index" do
    sign_in(users(:reader))

    get manifest_registries_url
    assert_redirected_to root_path
    assert_equal "You must be an admin to access restricted resources.", flash[:alert]
  end

  test "non-admin users should be redirected from show" do
    sign_in(users(:reader))

    get manifest_registry_url(@manifest_registry)
    assert_redirected_to root_path
    assert_equal "You must be an admin to access restricted resources.", flash[:alert]
  end

  test "non-admin users should be redirected from create" do
    sign_in(users(:reader))

    assert_no_difference("ManifestRegistry.count") do
      post manifest_registries_url, params: {
        manifest_registry: {url: "https://example.com/new-registry.json"}
      }
    end
    assert_redirected_to root_path
    assert_equal "You must be an admin to access restricted resources.", flash[:alert]
  end

  test "non-admin users should be redirected from destroy" do
    sign_in(users(:reader))

    assert_no_difference("ManifestRegistry.count") do
      delete manifest_registry_url(@manifest_registry)
    end
    assert_redirected_to root_path
    assert_equal "You must be an admin to access restricted resources.", flash[:alert]
  end

  test "non-admin users should be redirected from run" do
    sign_in(users(:reader))

    assert_no_enqueued_jobs do
      post run_manifest_registry_url(@manifest_registry)
    end
    assert_redirected_to root_path
    assert_equal "You must be an admin to access restricted resources.", flash[:alert]
  end
end
