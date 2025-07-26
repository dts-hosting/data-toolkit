class DataItem < ApplicationRecord
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity, counter_cache: true
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
    next unless completed?

    next current_task.touch if current_task.progress >= 100
    current_task.touch if rand < checkin_frequency # bumps task.updated_at
  end

  def checkin_frequency
    item_count = activity.data_items_count
    return 0 if item_count.zero?

    # cap 5% checkin, but lower as item count increases
    [Math.sqrt(item_count) / item_count, 0.05].min
  end

  def feedback_context = current_task.class.name
end
