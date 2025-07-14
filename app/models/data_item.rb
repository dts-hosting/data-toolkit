class DataItem < ApplicationRecord
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity
  belongs_to :current_task, class_name: "Task"

  enum :status, {
    pending: "pending", running: "running", succeeded: "succeeded", failed: "failed"
  }, default: :pending

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}

  after_update_commit do
    next unless succeeded? || failed?

    if current_task.running? && current_task.progress >= 100
      current_task.finalizer&.perform_later(current_task)
    elsif rand < 0.1
      current_task.touch # bumps task.updated_at
    end
  end

  def feedback_context = current_task.class.name
end
