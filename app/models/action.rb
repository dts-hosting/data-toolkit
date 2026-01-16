class Action < ApplicationRecord
  include Feedbackable
  include Progressable

  belongs_to :task
  belongs_to :data_item

  validates :task_id, uniqueness: {scope: :data_item_id}

  after_update_commit do
    next unless progress_completed?

    next task.touch if task.progress >= 100
    broadcast_task_progress if rand < task.checkin_frequency
  end

  def feedback_context = task.feedback_context

  scope :with_errors, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'errors') > 0") }
  scope :without_errors, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'errors') = 0") }
  scope :with_warnings, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'warnings') > 0") }

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
end
