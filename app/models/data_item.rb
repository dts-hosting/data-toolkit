class DataItem < ApplicationRecord
  belongs_to :activity
  belongs_to :current_task, class_name: "Task"

  enum :status, {pending: 0, succeeded: 1, failed: 2}, default: :pending

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}

  def fail!(feedback)
    update(status: :failed, feedback: feedback)
  end

  def success!
    update(status: :succeeded)
  end
end
