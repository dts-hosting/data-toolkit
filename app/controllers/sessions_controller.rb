class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    cspace_url = CollectionSpaceService.format_url(session_params[:cspace_url])
    email_address = session_params[:email_address]
    password = session_params[:password]
    client = CollectionSpaceService.client_for(cspace_url, email_address, password)

    if client.can_authenticate?
      user = User.find_or_create_by(cspace_url: cspace_url, email_address: email_address) do |user|
        version_data = client.version
        user.cspace_api_version = version_data.ui.version
        user.cspace_profile = version_data.ui.profile
        user.cspace_ui_version = version_data.api.joined
        user.password = password
      end
      user.update(password: password) if user.password != password
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Failed to authenticate with CollectionSpace."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def session_params
    params.permit(:cspace_url, :email_address, :password)
  end
end
