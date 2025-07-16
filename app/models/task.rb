class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :data_items, through: :activity
  has_many_attached :files

  enum :status, {
    pending: "pending",
    queued: "queued",
    running: "running",
    succeeded: "succeeded",
    review: "review",
    failed: "failed"
  }, default: :pending

  validates :type, :status, presence: true

  after_update_commit :broadcast_updates
  after_update_commit :handle_completion

  # tasks that are required to have succeeded for this task to run
  def dependencies
    []
  end

  # the job that runs when this task is complete (which can spawn other jobs etc.)
  def finalizer
    nil
  end

  # the primary job associated with this task (required)
  def handler
    raise NotImplementedError, "#{self.class} must implement #handler"
  end

  def ok_to_run?
    met_dependencies && pending? && started_at.nil?
  end

  def feedback_context = self.class.name

  def progress
    case status
    when "pending", "queued" then 0
    when "running" then calculate_progress
    when *PROGRESSED_STATUSES then 100
    else 0
    end
  end

  def run
    return unless ok_to_run?

    transaction do
      update!(status: "queued")
      data_items.update_all(
        current_task_id: id,
        status: "pending",
        feedback: nil,
        started_at: nil,
        completed_at: nil
      )
    end
    handler.perform_later(self)
  end

  def update_progress
    finalize_status if running? && calculate_progress >= 100
  end

  def self.display_name
    raise NotImplementedError
  end

  private

  def broadcast_updates
    broadcast_replace_to [activity, :tasks],
      target: dom_id(self),
      partial: "tasks/task",
      locals: {task: self}

    broadcast_update_to self,
      target: "#{dom_id(self)}_details",
      partial: "tasks/details",
      locals: {task: self}
  end

  def calculate_progress
    return 0 if data_items.empty?

    completed_items_ratio = data_items.where(status: [PROGRESSED_STATUSES]).count.to_f / data_items.count
    (completed_items_ratio * 100).round(2)
  end

  def finalize_status
    if data_items.where(status: "failed").exists?
      fail! # workflow cannot proceed beyond this point
    elsif data_items.where(status: "review").exists?
      suspend! # confirmation required for workflow to continue
    else
      success! # great, no problems
    end
  end

  def handle_completion
    if saved_change_to_status? && completed?
      # only run finalizer on first transitioning to a completed status
      # not when, for example, going from review -> succeeded
      previous_status = saved_change_to_status.first
      unless PROGRESSED_STATUSES.include?(previous_status)
        finalizer&.perform_later(self)
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
