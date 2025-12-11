# Exposes builder pattern functionality for defining an "activity".
module ActivityDefinition
  extend ActiveSupport::Concern

  class ActivityTypeConfiguration
    attr_accessor :name, :display_name, :file_requirement, :has_batch_config,
      :has_config_fields, :workflow, :data_config_type,
      :data_handler, :select_attributes, :boolean_attributes,
      :config_defaults, :validations

    def initialize(name)
      @name = name
      @display_name = nil
      @file_requirement = :none
      @has_batch_config = false
      @has_config_fields = false
      @workflow = []
      @data_config_type = nil
      @data_handler = nil
      @select_attributes = nil
      @boolean_attributes = nil
      @config_defaults = {}
      @validations = nil
    end
  end

  included do
    @@activity_types_registry = {}

    validate :activity_type_must_exist_in_registry
    validate :apply_activity_type_validations
    validates :type, presence: true
    before_validation :normalize_type_column

    def self.activity_types_registry
      @@activity_types_registry
    end
  end

  class_methods do
    def activity_type(name, &block)
      config = ActivityTypeConfiguration.new(name)
      yield(config) if block_given?
      @@activity_types_registry[name] = config
    end

    def activity_type_config(name)
      return nil unless name
      @@activity_types_registry[name.to_sym]
    end

    # Replacement for Descendents#descendants_by_display_name
    def activity_types_by_display_name
      @@activity_types_registry.transform_values(&:display_name).invert
    end

    # Replacement for Descendents#display_names
    def activity_type_display_names
      @@activity_types_registry.values.map(&:display_name).compact.sort
    end

    # Replacement for Descendents#find_type_by_param_name
    def find_activity_type_by_param_name(param_name)
      @@activity_types_registry.find do |_name, config|
        config.display_name&.parameterize == param_name
      end&.first
    end

    def requires_files?
      # This is now an instance method, keep class method for backwards compatibility
      # but it should be called on instances
      raise NotImplementedError, "requires_files? should be called on an instance"
    end
  end

  def activity_config
    self.class.activity_type_config(activity_type)
  end

  def activity_type
    type&.to_sym
  end

  def boolean_attributes
    activity_config&.boolean_attributes || BatchConfig.boolean_attributes
  end

  def data_config_type
    activity_config&.data_config_type
  end

  def data_handler
    return nil unless activity_config&.data_handler
    @data_handler ||= activity_config.data_handler.call(self)
  end

  def display_name
    activity_config&.display_name || type.to_s.titleize
  end

  def file_requirement
    activity_config&.file_requirement || :none
  end

  def has_batch_config?
    activity_config&.has_batch_config || false
  end

  def has_config_fields?
    activity_config&.has_config_fields || false
  end

  def requires_files?
    [:required_single, :required_multiple].include?(file_requirement)
  end

  def select_attributes
    activity_config&.select_attributes || BatchConfig.select_attributes
  end

  def workflow
    activity_config&.workflow || []
  end

  private

  def normalize_type_column
    if type.is_a?(Symbol)
      self.type = type.to_s
    end
  end

  def activity_type_must_exist_in_registry
    return if self.class.activity_types_registry.key?(activity_type)

    errors.add(:type, "unknown activity type: #{type}. Must be one of: #{self.class.activity_types_registry.keys.join(", ")}")
  end

  def apply_activity_type_validations
    return unless activity_config&.validations
    activity_config.validations.call(self)
  end
end
