class ManifestRegistriesController < AdminController
  before_action :set_manifest_registry, only: [:show, :destroy, :run]

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

  def destroy
    @manifest_registry.destroy
    redirect_to manifest_registries_path, notice: "Manifest registry was successfully deleted."
  rescue ActiveRecord::InvalidForeignKey
    redirect_to manifest_registries_path, alert: "Cannot delete manifest registry because it contains data configs that are currently in use."
  end

  def run
    ManifestRegistryImportJob.perform_later
    redirect_to manifest_registries_path, notice: "Registry import job has been queued."
  end

  private

  def manifest_registry_params
    params.require(:manifest_registry).permit(:url)
  end

  def set_manifest_registry
    @manifest_registry = ManifestRegistry.find(params[:id])
  end
end
