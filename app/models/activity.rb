class Activity < ApplicationRecord
  include Descendents

  belongs_to :data_config
  belongs_to :user
  has_many :data_items, dependent: :delete_all
  has_many :tasks # dependent: :destroy | NOTE: we handle this in create_history
  has_many_attached :files, dependent: :destroy
  has_one :batch_config, dependent: :destroy
  accepts_nested_attributes_for :batch_config

  validates :batch_config, presence: true, if: -> { self.class.has_batch_config? }
  validate :data_config, :is_eligible?

  with_options presence: true do
    validates :data_config, :label, :type, :user
  end

  validates :label, length: {minimum: 3}

  after_initialize :set_config_defaults, if: :new_record?
  after_create_commit do
    workflow.each do |task|
      tasks.create(type: task)
    end
  end

  after_update_commit :handle_advance
  before_destroy :create_history

  broadcasts_refreshes

  def boolean_attributes
    BatchConfig.boolean_attributes
  end

  def current_task
    tasks.where.not(progress_status: "pending").order(:created_at).last
  end

  def next_task
    tasks.where(progress_status: "pending").order(:created_at).first
  end

  def select_attributes
    BatchConfig.select_attributes
  end

  def summary
    return {} if tasks.empty?

    task = current_task || next_task
    {
      activity_user: user.email_address,
      activity_url: user.cspace_url,
      activity_type: self.class.display_name,
      activity_label: label,
      activity_data_config_type: data_config.config_type,
      activity_data_config_record_type: data_config.record_type,
      activity_created_at: created_at,
      task_type: task.class.display_name,
      task_status: task.status,
      task_feedback: task.feedback,
      task_started_at: task.started_at || Time.current,
      task_completed_at: task.completed_at
    }
  end

  def self.display_name
    raise NotImplementedError
  end

  # Subclasses should implement one of:
  # :none, :required_single, :required_multiple, :optional_multiple
  def self.file_requirement
    raise NotImplementedError
  end

  def self.has_batch_config?
    raise NotImplementedError
  end

  def self.has_config_fields?
    raise NotImplementedError
  end

  def self.requires_files?
    [:required_single, :required_multiple].include?(file_requirement)
  end

  private

  def create_history
    return if tasks.empty?

    History.create!(summary)
    tasks.destroy_all # we do this here to have access to task for history
  rescue => e
    Rails.logger.error "Failed to create history for activity #{id}: #{e.message}"
    errors.add(:base, "Unable to create history record")
    throw(:abort)
  end

  # TODO: for the moment we're just logging, but this would be a good spot for notifications
  def handle_advance
    return unless config.fetch("auto_advance", true)

    # if auto advanced transitioned from true -> false
    if saved_change_to_auto_advanced? && saved_change_to_auto_advanced.first == true && !auto_advanced
      Rails.logger.info "Activity #{id}: Auto-advance disabled"
    end

    # if the current_task is the last task and it was successful
    if current_task == tasks.last && current_task&.outcome_succeeded?
      Rails.logger.info "Activity #{id}: Workflow completed successfully"
    end
  end

  def is_eligible?
    return unless user

    if DataConfig.for(user, self).empty?
      errors.add(:data_config, "is not eligible for this activity")
    end
  end

  def set_config_defaults
    self.config = {
      auto_advance: true
    }.merge(config.symbolize_keys || {})
  end
end
