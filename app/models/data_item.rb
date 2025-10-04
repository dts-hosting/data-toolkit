class DataItem < ApplicationRecord
  include Feedbackable
  include TransitionsStatus

  belongs_to :activity, counter_cache: true
  belongs_to :current_task, class_name: "Task"

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}

  scope :without_errors, -> { where.not(status: "failed") }
  # TODO: if refactor data item status w/o outcomes when without_errors would look like (SQLite)
  # scope :without_errors, -> { where("feedback IS NOT NULL AND json_array_length(feedback, '$.errors') = 0") }

  after_update_commit do
    next unless completed?

    next current_task.touch if current_task.progress >= 100
    broadcast_task_progress if rand < checkin_frequency
  end

  def feedback_context = current_task.class.name

  private

  def broadcast_task_progress
    current_task.broadcast_action_to(
      current_task,
      action: :update,
      partial: "shared/card/progress",
      locals: {property: "Progress", value: current_task.progress},
      target: "task_#{current_task.id}_progress"
    )
  end

  def checkin_frequency
    item_count = activity.data_items_count
    return 0 if item_count.zero?

    # cap 10% checkin, but lower as item count increases
    [Math.sqrt(item_count) / item_count, 0.1].min
  end
end
