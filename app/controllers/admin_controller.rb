class AdminController < ApplicationController
  before_action :ensure_admin!

  private

  def ensure_admin!
    unless Current.user&.admin?
      redirect_to main_app.root_path, alert: "You must be an admin to access restricted resources."
    end
  end
end
