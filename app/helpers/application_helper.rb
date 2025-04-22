module ApplicationHelper
  include Pagy::Frontend

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
