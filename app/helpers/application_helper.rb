module ApplicationHelper
  include Pagy::Frontend

  def admin?
    authenticated? && Current.user.admin?
  end

  def config_checked?(record, field, value, default = false)
    current_value = record.config&.dig(field)
    current_value == value || (current_value.nil? && default)
  end

  def data_config_type_label(activity)
    label = activity.data_config_type.humanize
    label += " type" unless label.end_with?(" type")
    label
  end

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

  def task_status_color(status)
    case status.to_sym
    when :pending
      "secondary"
    when :queued
      "info"
    when :running
      "warning"
    when :succeeded
      "success"
    when :failed
      "danger"
    else
      "primary"
    end
  end
end
