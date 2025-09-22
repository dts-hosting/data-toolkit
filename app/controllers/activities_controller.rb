class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :destroy]
  before_action :verify_activity_type, only: [:new]

  def new
    @activity = @activity_type.new
    @activity.build_batch_config if @activity.class.has_batch_config?
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.user = Current.user

    if @activity.save
      redirect_to activity_path(@activity), notice: "#{@activity.class.display_name} was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
  end

  def destroy
    @activity.destroy
    redirect_to root_path, status: :see_other, notice: "Activity was successfully deleted."
  end

  private

  def set_activity
    accessible_activities = Activity.joins(:user)
      .where(
        "activities.user_id = ? OR users.cspace_url = ?",
        Current.user.id,
        Current.user.cspace_url
      )

    @activity = accessible_activities.find_by(id: params[:id])

    unless @activity
      redirect_to my_activities_url, alert: "You don't have permission to access this activity."
    end
  end

  def verify_activity_type
    @activity_type = Activity.find_type_by_param_name(params[:type])

    unless @activity_type
      redirect_to my_activities_url, flash: {alert: "Invalid activity type"}
    end
  end

  def activity_params
    base_params = [
      :type,
      :label,
      :data_config_id,
      {files: []},
      config: {},
      batch_config_attributes: BatchConfig.boolean_attributes + BatchConfig.select_attributes
    ]

    params.require(:activity).permit(base_params)
  end
end
