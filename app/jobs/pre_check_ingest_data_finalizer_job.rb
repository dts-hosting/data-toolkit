class PreCheckIngestDataFinalizerJob < ApplicationJob
  queue_as :default

  def perform(task)
    Rails.logger.info "#{self.class.name} started"
    feedback = task.feedback_for

    item_failures = task.data_items.where(status: "failed")

    log_finish && return if item_failures.empty?

    task.update!(feedback: item_failure_feedback_for(feedback, item_failures))
  rescue => e
    Rails.logger.error e.message
    feedback.add_to_errors(
      category: "application error",
      message: e.message,
      detail: e.backtrace.first
    )
  end

  private

  def log_finish
    Rails.logger.info "#{self.class.name} finished"
  end

  # Updating this to use new Feedback is still in progress
  def item_failure_feedback_for(feedback, failures)
    errs = failures.map { |item| item.feedback["errors"].keys }
      .flatten
      .uniq
    cat = "data item failures"
    msg = "#{failures.count} items in your data fail pre-check. Errors " \
      "received include: #{errs.join("; ")}"

    return {errors: {cat => [msg]}} unless feedback

    if feedback.key?(:errors)
      feedback[:errors][cat] = [msg]
    else
      feedback[:errors] = {cat => [msg]}
    end
  end
end
