module TaskDefinition
  extend ActiveSupport::Concern

  class TaskTypeConfiguration
    attr_accessor :name, :display_name_value, :handler_value, :action_handler_value,
      :finalizer_value, :dependencies, :auto_trigger_value

    def initialize(name)
      @name = name
      @dependencies = []
      @auto_trigger_value = false
    end

    def display_name(value = nil)
      return @display_name_value if value.nil?
      @display_name_value = value
    end

    def handler(value = nil)
      return @handler_value if value.nil?
      @handler_value = value
    end

    def action_handler(value = nil)
      return @action_handler_value if value.nil?
      @action_handler_value = value
    end

    def finalizer(value = nil)
      return @finalizer_value if value.nil?
      @finalizer_value = value
    end

    def depends_on(*task_types)
      return @dependencies if task_types.empty?
      @dependencies = task_types.flatten
    end

    def auto_trigger(value = nil)
      return @auto_trigger_value if value.nil?
      @auto_trigger_value = value
    end
  end

  included do
    @@task_types_registry = {}

    validate :task_type_must_exist_in_registry
    validates :type, presence: true
    before_validation :normalize_type_column

    after_create_commit :auto_run_if_configured

    def self.task_types_registry
      @@task_types_registry
    end
  end

  class_methods do
    def task_type(name, &block)
      config = TaskTypeConfiguration.new(name)
      config.instance_eval(&block) if block_given?
      @@task_types_registry[name] = config
    end

    def task_type_config(name)
      @@task_types_registry[name.to_sym]
    end
  end

  def action_handler
    task_config&.action_handler_value
  end

  def dependencies
    return [] unless task_config
    task_config.dependencies
  end

  def display_name
    task_config&.display_name_value || type.to_s.titleize
  end

  def finalizer
    task_config&.finalizer_value
  end

  def handler
    task_config&.handler_value || (raise NotImplementedError, "No handler configured for task type: #{type}")
  end

  def report_name
    display_name.parameterize(separator: "_")
  end

  def task_config
    self.class.task_type_config(task_type_symbol)
  end

  def task_type_symbol
    type&.to_sym
  end

  private

  def auto_run_if_configured
    return unless task_config&.auto_trigger_value
    run
  end

  def normalize_type_column
    if type.is_a?(Symbol)
      self.type = type.to_s
    end
  end

  def task_type_must_exist_in_registry
    return if type.blank?
    return if self.class.task_types_registry.key?(task_type_symbol)

    errors.add(:type, "unknown task type: #{type}. Must be one of: #{self.class.task_types_registry.keys.join(", ")}")
  end
end
