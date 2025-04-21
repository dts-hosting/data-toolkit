module HomeHelper
  def file_names(activity, max_files: 3)
    return "No files" if activity.files.blank?

    files = activity.files.take(max_files).map(&:filename).join(", ")
    if activity.files.count > max_files
      files += " etc."
    end
    files
  end

  def task_name(activity)
    return activity.current_task.class.display_name if activity.current_task
    return activity.next_task.class.display_name if activity.next_task

    ""
  end
end
