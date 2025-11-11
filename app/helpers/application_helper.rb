module ApplicationHelper
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

  def format_attached_files(files)
    content_tag :ul, class: "list-none" do
      files.map do |file|
        content_tag :li, class: "mb-1" do
          link_to(file.filename.to_s, rails_blob_path(file, disposition: "attachment"), class: "link link-info") +
            content_tag(:span, number_to_human_size(file.byte_size), class: "text-base-content/60 ml-2")
        end
      end.join.html_safe
    end
  end

  def format_task_status_badge(task_status)
    content_tag :span, class: "badge badge-#{task_status_color(task_status)}" do
      task_status_text(task_status)
    end
  end

  def icon_for_file(file)
    case file.content_type
    when "text/csv", "application/csv"
      icon "document-chart-bar", variant: :solid, class: "size-6 text-success"
    when /^image\//
      icon "photo", variant: :solid, class: "size-6 text-info"
    when /^video\//
      icon "video-camera", variant: :solid, class: "size-6 text-secondary"
    when "application/pdf"
      icon "document-text", variant: :solid, class: "size-6 text-error"
    else
      icon "document", variant: :solid, class: "size-6 text-base-content/70"
    end
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
    when :review
      "warning"
    when :failed
      "error"
    else
      "primary"
    end
  end

  def task_status_text(status)
    t("tasks.status.#{status}")
  end
end
