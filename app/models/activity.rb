class Activity < ApplicationRecord
  belongs_to :data_config
  belongs_to :user
  has_many :tasks, dependent: :destroy
  has_many_attached :files, dependent: :destroy

  validate :data_config, :is_eligible?

  with_options presence: true do
    validates :data_config, :type, :user
  end

  after_create_commit do
    workflow.each do |task|
      tasks.create(type: task)
    end
  end

  private

  def is_eligible?
    return unless user

    if DataConfig.for(user, self).empty?
      errors.add(:data_config, "is not eligible for this activity")
    end
  end
end
