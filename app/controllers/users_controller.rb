# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show update reset]
  before_action :authorize_user, only: %i[show update reset]
  before_action :set_profile_version_options, only: %i[show update]

  def show
  end

  def update
    data_config = DataConfig.where(config_type: DataConfig::PROFILE_VERSION_CONFIG_TYPES).find_by(
      id: profile_version_params[:profile_version_data_config_id]
    )

    unless data_config
      @user.errors.add(:base, "Select a supported profile and UI version")
      render :show, status: :unprocessable_content
      return
    end

    if @user.update(
      cspace_profile_override: data_config.profile,
      cspace_ui_version_override: data_config.version
    )
      redirect_to user_path(@user), notice: "Profile/version override was updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  def reset
    @user.update!(
      cspace_profile_override: nil,
      cspace_ui_version_override: nil
    )

    redirect_to user_path(@user), notice: "Profile/version override was removed."
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    unless @user
      redirect_to root_path,
        status: :not_found,
        alert: "User not found"
    end
  end

  def authorize_user
    unless authorized_to_view?(@user)
      redirect_to root_path,
        alert: "You are not authorized to access this page"
    end
  end

  def authorized_to_view?(user)
    return false unless Current.user

    Current.user.admin? || Current.user.is?(user)
  end

  def set_profile_version_options
    @profile_version_options = DataConfig.profile_version_options
  end

  def profile_version_params
    params.require(:user).permit(:profile_version_data_config_id)
  end
end
