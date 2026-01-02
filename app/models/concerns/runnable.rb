# Groups behavior related to "task" init/progression.
# In this app it's tightly coupled to the Task model,
# requiring task rlshps: activity, actions, data_items.
module Runnable
  extend ActiveSupport::Concern

  SUCCEEDED = "succeeded"
  FAILED = "failed"
  REVIEW = "review"

  included do
    include Progressable # depends on progress enum
    include TaskDefinition # runnables can define tasks

    after_touch :check_progress
    after_update_commit :handle_completion

    enum :outcome_status, {
      review: REVIEW,
      failed: FAILED,
      succeeded: SUCCEEDED
    }, prefix: :outcome

    def checkin_frequency
      item_count = activity.data_items_count
      return 0 if item_count.zero?

      # cap 10% checkin, but lower as item count increases
      [Math.sqrt(item_count) / item_count, 0.1].min
    end

    # Note: this overrides Progressable done! to add outcome
    def done!(outcome_status, feedback = nil)
      params = {
        progress_status: Progressable::COMPLETED,
        outcome_status: outcome_status,
        completed_at: Time.current,
        feedback: feedback
      }.compact
      update!(**params)
    end

    def ok_to_run?
      met_dependencies && progress_pending? && started_at.nil?
    end

    def progress
      case progress_status
      when Progressable::PENDING, Progressable::QUEUED then 0
      when Progressable::RUNNING then calculate_progress
      when Progressable::COMPLETED then 100
      else 0
      end
    end

    def run
      return unless ok_to_run?

      transaction do
        create_actions_for_data_items
        update!(progress_status: Progressable::QUEUED)
      end
      handler.perform_later(self)
    end

    def status
      progress_completed? ? outcome_status : progress_status
    end

    private

    def calculate_progress
      return 0 if actions.empty?

      completed_actions_ratio = actions.progress_completed.count.to_f / actions.count
      (completed_actions_ratio * 100).round
    end

    def check_progress
      finalize_status if progress_running? && calculate_progress >= 100
    end

    def create_actions_for_data_items
      all_data_items = activity.data_items # initially scope to all possible data items

      # Filter out items that have errors in ANY previous action
      data_item_ids_with_errors = Action.with_errors
        .where(data_item_id: all_data_items.select(:id))
        .distinct
        .pluck(:data_item_id)

      processable_items = all_data_items.where.not(id: data_item_ids_with_errors)

      processable_items.find_each do |data_item|
        actions.create!(data_item: data_item)
      end
    end

    def finalize_status
      if actions.with_errors.count == actions.count
        done!(FAILED)
      elsif actions.with_errors.exists? || actions.with_warnings.exists?
        done!(REVIEW)
      else
        done!(SUCCEEDED)
      end
    end

    def handle_completion
      # only advance when transitioning to a completed status and not when
      # updating outcome status, for example, going from review -> succeeded
      return unless saved_change_to_progress_status? && progress_completed?

      activity.trigger_auto_advance
    end

    def met_dependencies
      return true if dependencies.empty?

      dependencies.all? do |dependency|
        activity.tasks.exists?(type: dependency.to_s, outcome_status: SUCCEEDED)
      end
    end
  end
end
