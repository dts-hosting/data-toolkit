# frozen_string_literal: true

class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.new(user_params)
    if user.save
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_user_path, alert: "Account creation failed. Please try again."
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
