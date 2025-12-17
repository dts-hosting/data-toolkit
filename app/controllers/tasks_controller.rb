class TasksController < ApplicationController
  before_action :set_task, only: %i[show run]

  def show
  end

  def run
    if @task.user == Current.user
      @task.run
      redirect_to activity_path(@activity), notice: "Task was successfully queued."
    else
      redirect_to my_activities_url, alert: "You don't have permission to queue this task."
    end
  end

  private

  def set_task
    accessible_tasks = Task.joins(activity: :user)
      .where(
        "activities.id = ? AND users.cspace_url = ?",
        params[:activity_id],
        Current.collectionspace
      )

    @task = accessible_tasks.find_by(id: params[:id])

    unless @task
      redirect_to my_activities_url, alert: "You don't have permission to access this task."
      return
    end

    @activity = @task.activity
  end
end
