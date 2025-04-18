module HomeHelper
  def task_name(activity)
    return activity.current_task.class.display_name if activity.current_task
    return activity.next_task.class.display_name if activity.next_task

    ""
  end
end
