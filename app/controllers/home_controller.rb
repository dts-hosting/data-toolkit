class HomeController < ApplicationController
  def index
    @pagy, @activities = pagy(Current.user.activities.order(created_at: :desc))
  end

  def group_activities
    @pagy, @activities = pagy(
      Activity.joins(:user)
              .where(users: {cspace_url: Current.user.cspace_url})
              .where.not(user_id: Current.user.id)
              .order(created_at: :desc)
    )
    render :index
  end

  def history
    @pagy, @activities = pagy(
      History.where(
        activity_url: Current.user.cspace_url
      ).order(activity_created_at: :desc)
    )
    render :index
  end
end
