class Activity < ApplicationRecord
  include ActivityDefinition
  include Advanceable
  include Historical

  FAILED_EXPIRATION_DAYS = 7
  NON_FAILED_EXPIRATION_DAYS = 3

  # Disable STI - we use "type" column for activity type identifiers
  self.inheritance_column = :_type_disabled

  belongs_to :data_config
  belongs_to :user
  has_many :data_items, dependent: :destroy
  has_many :tasks # dependent: :destroy handled in Historical concern
  has_many_attached :files, dependent: :destroy
  has_one :batch_config, dependent: :destroy
  accepts_nested_attributes_for :batch_config

  validates :batch_config, presence: true, if: -> { has_batch_config? }
  validates :label, presence: true, length: {minimum: 3}
  validate :is_eligible?

  scope :accessible, -> {
    includes(:user, :data_config, :batch_config, :tasks)
      .joins(:user)
      .where(users: {cspace_url: Current.collectionspace})
  }

  scope :expired_failed, ->(expired = FAILED_EXPIRATION_DAYS) {
    joins(:tasks)
      .where(tasks: {outcome_status: Task::FAILED})
      .where(updated_at: ...expired.days.ago)
      .distinct
  }

  scope :expired_non_failed, ->(expired = NON_FAILED_EXPIRATION_DAYS) {
    where(updated_at: ...expired.days.ago)
      .where.not(id: joins(:tasks).where(tasks: {outcome_status: Task::FAILED}).select(:id))
  }

  after_initialize :set_config_defaults, if: :new_record?
  after_create do
    workflow.each do |task_type|
      tasks.create!(type: task_type)
    end
  end

  after_create_commit do
    tasks.reload.each do |task|
      task.send(:auto_run_if_configured)
    end
    tasks.reset
  end

  broadcasts_refreshes

  def current_task
    tasks.where.not(progress_status: Task::PENDING).order(:created_at).last
  end

  def done?
    last_task? && current_task.outcome_succeeded?
  end

  def last_task?
    current_task == tasks.last
  end

  def next_task
    tasks.where(progress_status: Task::PENDING).order(:created_at).first
  end

  # Activity type definitions
  activity_type :check_media_derivatives do
    display_name "Check Media Derivatives"
    file_requirement :one_or_more
    workflow :process_uploaded_files, :pre_check_ingest_data, :process_media_derivatives
    data_config_type "media_record_type"
    data_handler ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
  end

  activity_type :create_or_update_records do
    display_name "Create or Update Records"
    file_requirement :one
    has_batch_config true
    has_config_fields true
    workflow :process_uploaded_files, :pre_check_ingest_data
    data_config_type "record_type"
    data_handler ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
    config_defaults action: "create"
    validations ->(record) {
      record.errors.add(:config, "can't be blank") if record.config.blank?
    }
  end

  activity_type :delete_records do
    display_name "Delete Records"
    file_requirement :one
    has_batch_config true
    workflow [:process_uploaded_files]
    data_config_type "record_type"
    select_attributes [] # TODO: [:record_matchpoint]
  end

  activity_type :export_record_ids do
    display_name "Export Record IDs"
    data_config_type "record_type"
  end

  activity_type :import_terms do
    display_name "Import Terms"
    file_requirement :one
    data_config_type "term_list"
  end

  private

  def is_eligible?
    return unless user
    return unless activity_type
    return unless data_config_type

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
