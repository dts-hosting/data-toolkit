class DataItem < ApplicationRecord
  belongs_to :activity, counter_cache: true
  has_many :actions, dependent: :destroy
  has_many :tasks, through: :actions

  validates :data, presence: true
  validates :position, presence: true
  validates :position, uniqueness: {scope: :activity_id}
end
