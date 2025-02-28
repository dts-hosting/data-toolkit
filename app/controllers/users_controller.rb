# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show]

  def show
  end

  private

  def set_user
    # TODO: authorized if Current.user.admin? || Current.user.id == params.id
    @user = User.find(params[:id])
  end
end
