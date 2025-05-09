class TasksController < ApplicationController
  before_action :set_task, only: %i[show]

  def show
  end

  private

  def set_task
    accessible_tasks = Task.joins(activity: :user)
      .where(
        "activities.id = ? AND (activities.user_id = ? OR users.cspace_url = ?)",
        params[:activity_id],
        Current.user.id,
        Current.user.cspace_url
      )

    @task = accessible_tasks.find_by(id: params[:id])

    unless @task
      redirect_to my_activities_url, alert: "You don't have permission to access this task."
      return
    end

    @activity = @task.activity
  end
end
