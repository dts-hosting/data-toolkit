class ManifestRegistriesController < ApplicationController
  before_action :set_manifest_registry, only: [:show]

  def index
    @manifest_registry = ManifestRegistry.new
    @manifest_registries = ManifestRegistry.all.order(created_at: :desc)
  end

  def show
  end

  def create
    @manifest_registry = ManifestRegistry.new(manifest_registry_params)

    if @manifest_registry.save
      redirect_to manifest_registries_path, notice: "Manifest registry was successfully created."
    else
      @manifest_registries = ManifestRegistry.all.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def manifest_registry_params
    params.require(:manifest_registry).permit(:url)
  end

  def set_manifest_registry
    @manifest_registry = ManifestRegistry.find(params[:id])
  end
end
