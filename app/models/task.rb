class Task < ApplicationRecord
  belongs_to :activity
  has_many :data_items, through: :activity
  has_many_attached :files

  enum :status, {pending: 0, queued: 1, running: 2, succeeded: 3, failed: 4}, default: :pending

  validates :type, presence: true
  validates :status, presence: true

  # tasks that are required to have succeeded for this task to run
  def dependencies
    []
  end

  # the job that runs when this task is complete (which can spawn other jobs etc.)
  def finalizer
    nil
  end

  # the primary job associated with this task (required)
  def handler
    raise NotImplementedError
  end

  def ok_to_run?
    met_dependencies && pending? && started_at.nil?
  end

  def progress
    case status.to_sym
    when :pending, :queued
      0
    when :running
      calculate_progess
    when :succeeded, :failed
      100
    else
      0
    end
  end

  def run
    return unless ok_to_run?

    update(status: :queued)
    # data_items.update(status: :undetermined, feedback: nil) # reset
    handler.perform_later(self)
  end

  private

  def calculate_progess
    return 0 unless data_items.any?

    # TODO: data_items.where(status: :undetermined).count.to_f / data_items.count.to_f * 100
    50
  end

  def met_dependencies
    result = dependencies.find_all do |dependency|
      activity.tasks.where(type: dependency).where(status: :succeeded).exists?
    end
    result.size == dependencies.size
  end
end
