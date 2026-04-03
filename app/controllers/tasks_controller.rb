class TasksController < ApplicationController
  before_action :set_task, only: %i[show run]

  def show
  end

  def run
    if Current.user.is? @task.user
      @task.run
      redirect_to activity_path(@activity), notice: "Task was successfully queued."
    else
      redirect_to my_activities_url, alert: "You don't have permission to queue this task."
    end
  end

  private

  def set_task
    @activity = Activity.accessible.find_by(id: params[:activity_id])

    unless @activity
      redirect_to my_activities_url, alert: "You don't have permission to access this task."
      return
    end

    @task = @activity.tasks.find_by(id: params[:id])

    unless @task
      redirect_to my_activities_url, alert: "You don't have permission to access this task."
    end
  end
end
