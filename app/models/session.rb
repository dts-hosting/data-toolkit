class Session < ApplicationRecord
  belongs_to :user

  def self.sweep(time = 2.hours)
    where(updated_at: ...time.ago).or(where(created_at: ...1.day.ago)).delete_all
  end
end
