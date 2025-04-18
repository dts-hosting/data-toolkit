class HomeController < ApplicationController
  def index
    @pagy, @activities = pagy(
      Activity.joins(:user)
              .where(users: {cspace_url: Current.user.cspace_url})
              .order(created_at: :desc)
    )
  end

  def my_activities
    @pagy, @activities = pagy(Current.user.activities.order(created_at: :desc))
    render :index
  end
end
