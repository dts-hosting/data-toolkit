class Activity < ApplicationRecord
  include ActivityDefinition

  # Disable STI - we use "type" column for activity type identifiers
  self.inheritance_column = :_type_disabled

  belongs_to :data_config
  belongs_to :user
  has_many :data_items, dependent: :destroy
  has_many :tasks # dependent: :destroy | NOTE: we handle this in create_history
  has_many_attached :files, dependent: :destroy
  has_one :batch_config, dependent: :destroy
  accepts_nested_attributes_for :batch_config

  validates :batch_config, presence: true, if: -> { has_batch_config? }
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

  # Activity type definitions
  activity_type :check_media_derivatives do |a|
    a.display_name = "Check Media Derivatives"
    a.file_requirement = :required_multiple
    a.has_batch_config = false
    a.has_config_fields = false
    a.workflow = [:process_uploaded_files, :pre_check_ingest_data, :process_media_derivatives]
    a.data_config_type = "media_record_type"
    a.data_handler = ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
    a.validations = ->(record) {
      record.errors.add(:files, "can't be blank") if record.files.blank?
      record.errors.add(:files, "must have at least one file") if record.files.length < 1
    }
  end

  activity_type :create_or_update_records do |a|
    a.display_name = "Create or Update Records"
    a.file_requirement = :required_single
    a.has_batch_config = true
    a.has_config_fields = true
    a.workflow = [:process_uploaded_files, :pre_check_ingest_data]
    a.data_config_type = "record_type"
    a.data_handler = ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
    a.config_defaults = {action: "create", auto_advance: true}
    a.validations = ->(record) {
      record.errors.add(:files, "can't be blank") if record.files.blank?
      record.errors.add(:files, "must have exactly one file") if record.files.length != 1
      record.errors.add(:config, "can't be blank") if record.config.blank?
    }
  end

  activity_type :delete_records do |a|
    a.display_name = "Delete Records"
    a.file_requirement = :required_single
    a.has_batch_config = true
    a.has_config_fields = false
    a.workflow = [:process_uploaded_files]
    a.data_config_type = "record_type"
    a.select_attributes = [] # TODO: [:record_matchpoint]
    a.validations = ->(record) {
      record.errors.add(:files, "can't be blank") if record.files.blank?
      record.errors.add(:files, "must have exactly one file") if record.files.length != 1
    }
  end

  activity_type :export_record_ids do |a|
    a.display_name = "Export Record IDs"
    a.file_requirement = :none
    a.has_batch_config = false
    a.has_config_fields = false
    a.workflow = []
    a.data_config_type = "record_type"
  end

  activity_type :import_terms do |a|
    a.display_name = "Import Terms"
    a.file_requirement = :required_single
    a.has_batch_config = false
    a.has_config_fields = false
    a.workflow = []
    a.data_config_type = "term_list"
    a.validations = ->(record) {
      record.errors.add(:files, "can't be blank") if record.files.blank?
      record.errors.add(:files, "must have exactly one file") if record.files.length != 1
    }
  end

  def current_task
    tasks.where.not(progress_status: Task::PENDING).order(:created_at).last
  end

  def next_task
    tasks.where(progress_status: Task::PENDING).order(:created_at).first
  end

  def summary
    return {} if tasks.empty?

    task = current_task || next_task
    {
      activity_user: user.email_address,
      activity_url: user.cspace_url,
      activity_type: display_name,
      activity_label: label,
      activity_data_config_type: data_config.config_type,
      activity_data_config_record_type: data_config.record_type,
      activity_created_at: created_at,
      task_type: task.display_name,
      task_status: task.status,
      task_feedback: task.feedback,
      task_started_at: task.started_at || Time.current,
      task_completed_at: task.completed_at
    }
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
    return unless activity_type

    if DataConfig.for(user, self).empty?
      errors.add(:data_config, "is not eligible for this activity")
    end
  end

  def set_config_defaults
    defaults = {auto_advance: true}
    if activity_config&.config_defaults
      defaults = defaults.merge(activity_config.config_defaults)
    end
    self.config = defaults.merge((config || {}).symbolize_keys)
  end
end
