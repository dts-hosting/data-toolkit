class DataItem < ApplicationRecord
  belongs_to :activity

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}
end
