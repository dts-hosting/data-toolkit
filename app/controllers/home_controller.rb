class HomeController < ApplicationController
  def index
    @pagy, @activities = pagy(
      Current.user.activities
        .includes(:user, :data_config, :tasks)
        .order(created_at: :desc)
    )
  end

  def group_activities
    @pagy, @activities = pagy(
      Activity.includes(:user, :data_config, :tasks)
              .joins(:user)
              .where(users: {cspace_url: Current.collectionspace})
              .where.not(user_id: Current.user.id)
              .order(created_at: :desc)
    )
    render :index
  end

  def history
    @pagy, @activities = pagy(
      History.where(
        activity_url: Current.collectionspace
      ).order(activity_created_at: :desc)
    )
    render :index
  end
end
