class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include Progressable

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :actions
  has_many :data_items, through: :actions
  has_many_attached :files

  enum :outcome_status, {
    review: "review",
    failed: "failed",
    succeeded: "succeeded"
  }, prefix: :outcome

  validates :type, :progress_status, presence: true

  broadcasts_refreshes
  after_touch :check_progress
  after_update_commit :handle_completion

  # the action level job associated with this task
  def action_handler
    raise NotImplementedError, "#{self.class} must implement #action_handler"
  end

  # tasks that are required to have succeeded for this task to run
  def dependencies
    []
  end

  # the job that runs when this task is complete (which can spawn other jobs etc.)
  def finalizer
    nil
  end

  def finish!(outcome_status, feedback = nil)
    params = {
      progress_status: "completed",
      outcome_status: outcome_status,
      completed_at: Time.current,
      feedback: feedback
    }.compact
    update!(**params)
  end

  # the entrypoint job associated with this task (required)
  def handler
    raise NotImplementedError, "#{self.class} must implement #handler"
  end

  def has_feedback?
    progress_completed? &&
      (feedback_for.displayable? || actions.where.not(feedback: nil).any?)
  end

  def ok_to_run?
    met_dependencies && progress_pending? && started_at.nil?
  end

  def feedback_context = self.class.name

  def progress
    case progress_status
    when "pending", "queued" then 0
    when "running" then calculate_progress
    when "completed" then 100
    else 0
    end
  end

  def run
    return unless ok_to_run?

    # Create actions for data items that don't have errors from previous tasks
    # Actions track the relationship between this task and the data items it processes
    transaction do
      create_actions_for_data_items
      update!(progress_status: "queued")
    end
    handler.perform_later(self)
  end

  def self.display_name
    raise NotImplementedError
  end

  private

  def calculate_progress
    return 0 if actions.empty?

    completed_actions_ratio = actions.progress_completed.count.to_f / actions.count
    (completed_actions_ratio * 100).round
  end

  def check_progress
    finalize_status if progress_running? && calculate_progress >= 100
  end

  def create_actions_for_data_items
    all_data_items = activity.data_items # initially scope to all possible data items

    # Filter out items that have errors in ANY previous action
    data_item_ids_with_errors = Action.with_errors
      .where(data_item_id: all_data_items.select(:id))
      .distinct
      .pluck(:data_item_id)

    processable_items = all_data_items.where.not(id: data_item_ids_with_errors)

    processable_items.find_each do |data_item|
      actions.create!(data_item: data_item)
    end
  end

  def finalize_status
    if actions.with_errors.count == actions.count
      update!(outcome_status: "failed", progress_status: "completed", completed_at: Time.current)
    elsif actions.with_errors.exists? || actions.with_warnings.exists?
      update!(outcome_status: "review", progress_status: "completed", completed_at: Time.current)
    else
      update!(outcome_status: "succeeded", progress_status: "completed", completed_at: Time.current)
    end
  end

  def handle_completion
    # only run finalizer or auto advance when transitioning to a completed status
    # and not when updating outcome status, for example, going from review -> succeeded
    return unless progress_status_changed? && progress_completed?

    finalizer&.perform_later(self)

    if outcome_succeeded? && activity.config.fetch("auto_advance", true)
      activity.update(auto_advanced: true) unless activity.auto_advanced?
      activity.next_task&.run
    elsif activity.auto_advanced?
      activity.update(auto_advanced: false)
    end
  end

  def met_dependencies
    return true if dependencies.empty?

    dependencies.all? do |dependency|
      activity.tasks.exists?(type: dependency.to_s, outcome_status: "succeeded")
    end
  end
end
