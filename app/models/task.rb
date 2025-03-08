class Task < ApplicationRecord
  include TransitionsStatus

  belongs_to :activity
  has_many :data_items, through: :activity
  has_many_attached :files

  enum :status, {pending: 0, queued: 1, running: 2, succeeded: 3, failed: 4}, default: :pending

  validates :type, :status, presence: true

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

  def progress
    case status.to_sym
    when :pending, :queued then 0
    when :running
      current_progress = calculate_progress
      finish_up if current_progress >= 100
      current_progress
    when :succeeded, :failed then 100
    else 0
    end
  end

  def run
    return unless ok_to_run?

    transaction do
      update!(status: :queued)
      data_items.update_all(
        current_task_id: id,
        status: :pending,
        feedback: nil,
        started_at: nil,
        completed_at: nil
      )
    end
    handler.perform_later(self)
  end

  private

  def calculate_progress
    return 0 if data_items.empty?

    completed_items_ratio = data_items.where(status: [:failed, :succeeded]).count.to_f / data_items.count
    (completed_items_ratio * 100).round(2)
  end

  def finish_up
    data_items.where(status: :failed).exists? ? fail! : success!
    finalizer&.perform_later(self)
  end

  def met_dependencies
    return true if dependencies.empty?

    dependencies.all? do |dependency|
      activity.tasks.exists?(type: dependency.to_s, status: :succeeded)
    end
  end
end
