class Activity < ApplicationRecord
  include Descendents

  belongs_to :data_config
  belongs_to :user
  has_many :data_items, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many_attached :files, dependent: :destroy
  has_one :batch_config, dependent: :destroy
  accepts_nested_attributes_for :batch_config

  validates :batch_config, presence: true, if: -> { requires_batch_config? }
  validate :data_config, :is_eligible?

  with_options presence: true do
    validates :data_config, :type, :user
  end

  after_create_commit do
    workflow.each do |task|
      tasks.create(type: task)
    end
  end

  def current_task
    tasks.where.not(status: "pending").order(:created_at).last
  end

  def next_task
    tasks.where(status: "pending").order(:created_at).first
  end

  # Used to determine whether to include fields for batch config in ui
  def requires_batch_config?
    raise NotImplementedError
  end

  def self.display_name
    raise NotImplementedError
  end

  private

  def is_eligible?
    return unless user

    if DataConfig.for(user, self).empty?
      errors.add(:data_config, "is not eligible for this activity")
    end
  end
end
