class History < ApplicationRecord
  validates :activity_user, :activity_url, :activity_type, :activity_label, :activity_created_at, presence: true
  validates :task_type, :task_status, presence: true
end
