class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    authenticate_user
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def authenticate_user
    client = build_client

    if client.can_authenticate?
      handle_authentication(client)
    else
      authentication_failed
    end
  end

  def build_client
    CollectionSpaceService.client_for(
      session_params[:cspace_url],
      session_params[:email_address],
      session_params[:password]
    )
  end

  def handle_authentication(client)
    user = find_or_create_user(client)

    if user.valid?
      update_user_if_needed(user)
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      version_fetch_failed
    end
  end

  def find_or_create_user(client)
    User.find_or_create_by(
      cspace_url: client.config.base_uri,
      email_address: session_params[:email_address]
    ) do |user|
      set_user_data(user, client)
    end
  end

  def set_user_data(user, client)
    version_data = client.version
    user.cspace_api_version = version_data.api.joined
    user.cspace_profile = version_data.ui.profile
    user.cspace_ui_version = version_data.ui.version
    user.password = session_params[:password]
  end

  def update_user_if_needed(user)
    user.update(password: session_params[:password]) if user.password != session_params[:password]
  end

  def authentication_failed
    redirect_to new_session_path, alert: "Failed to authenticate with CollectionSpace."
  end

  def version_fetch_failed
    redirect_to new_session_path, alert: "Failed to access version information from CollectionSpace."
  end

  def session_params
    params.permit(:cspace_url, :email_address, :password)
  end
end
