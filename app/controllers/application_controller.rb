class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :resume_session
  before_action :set_scout_context

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def set_scout_context
    if Current.user.is_a?(User)
      ScoutApm::Context.add_user(id: Current.user.id)
      ScoutApm::Context.add(cspace_url: Current.user.cspace_url)
    end
  end
end
