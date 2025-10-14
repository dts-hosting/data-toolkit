class GenericFeedbackReportJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for
    feedback_actions = task.actions.where.not(feedback: nil)

    log_finish && return if feedback_actions.empty?

    file_name = "#{task.class.report_name}_report_#{task.id}.csv"
    file_path = Rails.root.join("tmp", file_name)
    # TODO: may want / need to not hardcode the format eventually
    report = FeedbackReport::CSV.new(feedback_actions, file_path)
    report.generate

    task.files.attach(
      io: File.open(file_path),
      filename: file_name,
      content_type: "text/csv"
    )
    feedback.add_to_messages(subtype: :report_generated)
    task.update(feedback: feedback)
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(subtype: :application_error, details: e)
    task.update(feedback: feedback)
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end
end
