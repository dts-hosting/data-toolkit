# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show]
  before_action :authorize_user, only: %i[show]

  def show
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
    # TODO: return true if Current.user.admin?
    return false unless Current.user

    Current.user.id == user.id
  end
end
