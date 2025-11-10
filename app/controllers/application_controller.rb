class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :resume_session
  before_action :set_scout_context

  def set_scout_context
    if Current.user.is_a?(User)
      ScoutApm::Context.add_user(id: Current.user.id)
      ScoutApm::Context.add(cspace_url: Current.user.cspace_url)
    end
  end
end
