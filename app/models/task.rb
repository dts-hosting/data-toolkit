class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :current_data_items, foreign_key: :current_task_id, class_name: "DataItem"
  has_many :data_items, through: :activity
  has_many_attached :files

  validates :type, :status, presence: true

  broadcasts_refreshes
  after_touch :check_progress
  after_update_commit :handle_completion

  # tasks that are required to have succeeded for this task to run
  def dependencies
    []
  end

  # the job that runs when this task is complete (which can spawn other jobs etc.)
  def finalizer
    nil
  end

  # the entrypoint job associated with this task (required)
  def handler
    raise NotImplementedError, "#{self.class} must implement #handler"
  end

  def has_feedback?
    completed? && (feedback_for.displayable? ||
      (data_items.first&.current_task == self &&
      data_items.where.not(feedback: nil).any?))
  end

  # the data item level job associated with this task
  def data_item_handler
    raise NotImplementedError, "#{self.class} must implement #data_item_handler"
  end

  def ok_to_run?
    met_dependencies && pending? && started_at.nil?
  end

  def feedback_context = self.class.name

  def progress
    case status
    when "pending", "queued" then 0
    when "running" then calculate_progress
    when *COMPLETION_STATUSES then 100
    else 0
    end
  end

  def run
    return unless ok_to_run?

    # Reset data item state: data items are shared by tasks
    # Items with errors are not reset so can be handled specifically (or ignored)
    # Feedback is not reset so can be carried through workflows
    transaction do
      update!(status: "queued", processable_count: data_items.without_errors.count)
      data_items.without_errors.update_all(
        current_task_id: id,
        status: "pending",
        started_at: nil,
        completed_at: nil
      )
    end
    handler.perform_later(self)
  end

  def self.display_name
    raise NotImplementedError
  end

  private

  def calculate_progress
    return 0 if data_items.empty?

    completed_items_ratio = data_items.where(status: COMPLETION_STATUSES).count.to_f / data_items.count
    (completed_items_ratio * 100).round
  end

  def check_progress
    finalize_status if running? && calculate_progress >= 100
  end

  def finalize_status
    if current_data_items.where(status: "failed").count == current_data_items.count
      fail! # everything has failed, cannot proceed beyond this point
    elsif current_data_items.where(status: "failed").exists? || current_data_items.where(status: "review").exists?
      suspend! # confirmation required for workflow to continue
    else
      success! # great, no problems
    end
  end

  def handle_completion
    if saved_change_to_status? && completed?
      # only run finalizer or auto advance on first transitioning to a completed
      # status and not when, for example, going from review -> succeeded
      previous_status = saved_change_to_status.first
      unless COMPLETION_STATUSES.include?(previous_status)
        if succeeded? && activity.config.fetch("auto_advance", true)
          # we have to skip running any defined finalizer in the
          # case of auto-advance because item state is reset
          activity.update(auto_advanced: true) unless activity.auto_advanced?
          activity.next_task&.run
        else
          activity.update(auto_advanced: false) if activity.auto_advanced?
          finalizer&.perform_later(self)
        end
      end
    end
  end

  def met_dependencies
    return true if dependencies.empty?

    dependencies.all? do |dependency|
      activity.tasks.exists?(type: dependency.to_s, status: "succeeded")
    end
  end
end
