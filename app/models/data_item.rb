class DataItem < ApplicationRecord
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity
  belongs_to :current_task, class_name: "Task"

  enum :status, {
    pending: "pending",
    running: "running",
    succeeded: "succeeded",
    review: "review",
    failed: "failed"
  }, default: :pending

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}

  after_update_commit do
    next unless Task::PROGRESSED_STATUSES.include?(status)

    next current_task.update_progress if current_task.progress >= 100
    current_task.touch if rand < 0.1 # bumps task.updated_at
  end

  def feedback_context = current_task.class.name
end
