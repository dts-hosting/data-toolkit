class DataItem < ApplicationRecord
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

    next current_task.update_progress if current_task.progress >= 100
    current_task.touch if rand < 0.1 # bumps task.updated_at
  end
end
