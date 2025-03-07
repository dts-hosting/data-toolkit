class DataItem < ApplicationRecord
  belongs_to :activity

  enum :status, {pending: 0, succeeded: 1, failed: 2}, default: :pending

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}
end
