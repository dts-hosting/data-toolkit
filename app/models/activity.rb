class Activity < ApplicationRecord
  include ActivityDefinition
  include AutoAdvanceable
  include Historical

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

  after_initialize :set_config_defaults, if: :new_record?
  after_create_commit do
    workflow.each do |task|
      tasks.create(type: task)
    end
  end

  broadcasts_refreshes

  # Activity type definitions
  activity_type :check_media_derivatives do |a|
    a.display_name = "Check Media Derivatives"
    a.file_requirement = :one_or_more
    a.has_batch_config = false
    a.has_config_fields = false
    a.workflow = [:process_uploaded_files, :pre_check_ingest_data, :process_media_derivatives]
    a.data_config_type = "media_record_type"
    a.data_handler = ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
  end

  activity_type :create_or_update_records do |a|
    a.display_name = "Create or Update Records"
    a.file_requirement = :one
    a.has_batch_config = true
    a.has_config_fields = true
    a.workflow = [:process_uploaded_files, :pre_check_ingest_data]
    a.data_config_type = "record_type"
    a.data_handler = ->(activity) { CollectionSpaceMapper.single_record_type_handler_for(activity) }
    a.config_defaults = {action: "create"}
    a.validations = ->(record) {
      record.errors.add(:config, "can't be blank") if record.config.blank?
    }
  end

  activity_type :delete_records do |a|
    a.display_name = "Delete Records"
    a.file_requirement = :one
    a.has_batch_config = true
    a.has_config_fields = false
    a.workflow = [:process_uploaded_files]
    a.data_config_type = "record_type"
    a.select_attributes = [] # TODO: [:record_matchpoint]
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
    a.file_requirement = :one
    a.has_batch_config = false
    a.has_config_fields = false
    a.workflow = []
    a.data_config_type = "term_list"
  end

  def current_task
    tasks.where.not(progress_status: Task::PENDING).order(:created_at).last
  end

  def next_task
    tasks.where(progress_status: Task::PENDING).order(:created_at).first
  end

  private

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
