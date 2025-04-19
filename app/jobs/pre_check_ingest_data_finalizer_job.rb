class PreCheckIngestDataFinalizerJob < ApplicationJob
  queue_as :default

  # This job spawns a sub-job for each data item
  def perform(task)
    Rails.logger.info "#{self.class.name} started"

    item_failures = task.data_items.where(status: "failed")

    if item_failures.empty?
      log_finish && return
    end

    # debugger
    task.update!(status: "failed",
      feedback: failure_feedback_for(task, item_failures))
  rescue => e
    Rails.logger.error e.message
    task.update!(feedback: app_error_feedback_for(task, e))
  end

  private

  def log_finish
    Rails.logger.info "#{self.class.name} finished"
  end

  # TODO: rework with better handling of feedback
  def failure_feedback_for(task, failures)
    feedback = task.feedback
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

  def app_error_feedback_for(task, e)
    feedback = task.feedback
    return {errors: {"application error" => [e.message]}} unless feedback

    if feedback.key?(:errors) && feedback[:errors].key?("application error")
      feedback[:errors]["application error"] << e.message
    elsif feedback.key?(:errors)
      feedback[:errors]["application error"] = [e.message]
    else
      feedback[:errors] = {"application error" => [e.message]}
    end
    feedback
  end
end
