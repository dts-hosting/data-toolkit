# Exposes builder pattern functionality for defining a "task".
module TaskDefinition
  extend ActiveSupport::Concern

  class TaskTypeConfiguration
    attr_accessor :name, :display_name, :handler, :action_handler,
      :finalizer, :dependencies, :auto_trigger

    def initialize(name)
      @name = name
      @display_name = nil
      @handler = nil
      @action_handler = nil
      @finalizer = nil
      @dependencies = []
      @auto_trigger = false
    end

    def depends_on(*task_types)
      return @dependencies if task_types.empty?
      @dependencies = task_types.flatten
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
    task_config&.action_handler
  end

  def dependencies
    return [] unless task_config
    task_config.dependencies
  end

  def display_name
    task_config&.display_name || type.to_s.titleize
  end

  def finalizer
    task_config&.finalizer
  end

  def handler
    task_config&.handler || (raise NotImplementedError, "No handler configured for task type: #{type}")
  end

  def report_name
    display_name.parameterize(separator: "_")
  end

  def task_config
    self.class.task_type_config(task_type)
  end

  def task_type
    type&.to_sym
  end

  private

  def auto_run_if_configured
    return unless task_config&.auto_trigger
    run
  end

  def normalize_type_column
    if type.is_a?(Symbol)
      self.type = type.to_s
    end
  end

  def task_type_must_exist_in_registry
    return if self.class.task_types_registry.key?(task_type)

    errors.add(:type, "unknown task type: #{type}. Must be one of: #{self.class.task_types_registry.keys.join(", ")}")
  end
end
