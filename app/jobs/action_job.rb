# Base for per-item jobs (a task's action_handler).
# Subclasses implement #process and add to `feedback`; the base guarantees
# the action is always started and completed, including on error.
class ActionJob < ApplicationJob
  queue_as :default

  # Jobs that call the CollectionSpace API opt in with `limits_client_concurrency`.
  # It caps how many run at once per CollectionSpace client (instance), so one
  # large task cannot occupy every worker thread or flood that instance. Jobs
  # that only touch local data (e.g. pre-checks) stay unlimited: the limit makes
  # enqueueing slower (each job takes a semaphore one by one instead of a bulk
  # insert), which only pays off where there is something to protect.
  # Over-cap jobs wait as Solid Queue blocked executions, not ready ones, so
  # PublishQueueSizeJob.demand_slots accounts for them when autoscaling.
  # The group is shared so the cap spans every opted-in ActionJob subclass.
  CLIENT_CONCURRENCY = ENV.fetch("CLIENT_CONCURRENCY", 10).to_i
  CONCURRENCY_GROUP = "CollectionSpaceApi"

  def self.limits_client_concurrency
    limits_concurrency to: CLIENT_CONCURRENCY,
      key: ->(activity, _action) { ActionJob.client_key(activity) },
      group: CONCURRENCY_GROUP,
      duration: 15.minutes
  end

  # The key proc runs at class level, hence a class method.
  def self.client_key(activity)
    activity.user.cspace_url.to_s.strip.downcase.chomp("/")
  end

  def perform(activity, action)
    # Re-runs of a completed action are no-ops
    return if action.progress_completed?

    WorkflowManager.start_action(action)
    # Start fresh: a run's results replace, never append to, stored feedback.
    feedback = Feedback.new(action.feedback_context)
    process(activity, action, feedback)
    complete(action, feedback)
  rescue => e
    Rails.logger.error "#{self.class.name} action=#{action.id}: #{e.class} #{e.message}"
    feedback ||= Feedback.new(action.feedback_context)
    feedback.add_to_errors(subtype: :application_error, details: e)
    complete(action, feedback)
  end

  private

  def process(activity, action, feedback)
    raise NotImplementedError, "#{self.class.name} must implement #process"
  end

  # Store nil rather than empty feedback so `where.not(feedback: nil)` (finalizers,
  # reports) only touches actions that have something to say.
  def complete(action, feedback)
    WorkflowManager.complete_action(action, feedback: feedback.displayable? ? feedback : nil)
  end
end
