class Action < ApplicationRecord
  include Feedbackable
  include Progressable

  belongs_to :task
  belongs_to :data_item

  validates :task_id, uniqueness: {scope: :data_item_id}

  after_update_commit do
    next unless saved_change_to_progress_status? && progress_completed?

    TaskOrchestrator.action_completed(self)
  end

  def feedback_context = task.feedback_context

  scope :with_errors, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'errors') > 0") }
  scope :without_errors, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'errors') = 0") }
  scope :with_warnings, -> { where("feedback IS NOT NULL AND jsonb_array_length(feedback->'warnings') > 0") }
end
