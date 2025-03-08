class DataItem < ApplicationRecord
  include TransitionsStatus

  belongs_to :activity
  belongs_to :current_task, class_name: "Task"

  enum :status, {pending: 0, running: 1, succeeded: 2, failed: 3}, default: :pending

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}
end
