class Action < ApplicationRecord
  include Feedbackable
  include Progressable

  belongs_to :task
  belongs_to :data_item

  validates :task_id, uniqueness: {scope: :data_item_id}

  after_update_commit do
    next unless progress_completed?

    next task.touch if task.progress >= 100
    broadcast_task_progress if rand < checkin_frequency
  end

  def feedback_context = task.class.name

  scope :with_errors, -> { where("feedback IS NOT NULL AND json_array_length(feedback, '$.errors') > 0") }
  scope :without_errors, -> { where("feedback IS NOT NULL AND json_array_length(feedback, '$.errors') = 0") }
  scope :with_warnings, -> { where("feedback IS NOT NULL AND json_array_length(feedback, '$.warnings') > 0") }

  def done!(feedback = nil)
    params = {
      progress_status: "completed",
      completed_at: Time.current,
      feedback: feedback
    }.compact
    update!(**params)
  end

  private

  def broadcast_task_progress
    broadcast_action_to(
      task,
      action: :update,
      partial: "shared/card/progress",
      locals: {property: "Progress", value: task.progress},
      target: "task_#{task.id}_progress"
    )
  end

  def checkin_frequency
    item_count = task.activity.data_items_count
    return 0 if item_count.zero?

    # cap 10% checkin, but lower as item count increases
    [Math.sqrt(item_count) / item_count, 0.1].min
  end
end
