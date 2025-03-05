class DataItem < ApplicationRecord
  belongs_to :activity

  validates :data, presence: true
  validates :position, presence: true
  validates_uniqueness_of :position, scope: :activity_id
end
