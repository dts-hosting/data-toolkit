# Groups behavior related to "task" init/progression.
# In this app it's tightly coupled to the Task model,
# requiring task rlshps: activity, actions, data_items.
module Runnable
  extend ActiveSupport::Concern

  BULK_INSERT_BATCH_SIZE = 1000

  SUCCEEDED = "succeeded"
  FAILED = "failed"
  REVIEW = "review"

  included do
    include Progressable # depends on progress enum
    include TaskDefinition # runnables can define tasks

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

      should_enqueue = false
      with_lock do
        next unless ok_to_run?

        if action_handler && create_actions_for_data_items.zero?
          done!(FAILED, no_processable_items_feedback)
        else
          update!(progress_status: Progressable::QUEUED)
          should_enqueue = true
        end
      end
      handler.perform_later(self) if should_enqueue
    end

    def status
      progress_completed? ? outcome_status : progress_status
    end

    private

    def calculate_progress
      return 0 if actions_count.zero?

      ((actions_completed_count.to_f / actions_count) * 100).round
    end

    def create_actions_for_data_items
      all_data_items = activity.data_items

      errored_items = Action.with_errors
        .where(data_item_id: all_data_items.select(:id))
        .select(:data_item_id)

      processable_items = all_data_items.where.not(id: errored_items)

      now = Time.current
      inserted_count = 0

      processable_items.in_batches(of: BULK_INSERT_BATCH_SIZE) do |batch|
        records = batch.pluck(:id).map do |data_item_id|
          {task_id: id, data_item_id: data_item_id, progress_status: Progressable::PENDING,
           created_at: now, updated_at: now}
        end

        result = Action.insert_all(records)
        inserted_count += result.count
      end

      update_column(:actions_count, actions.count)
      inserted_count
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

    def no_processable_items_feedback
      feedback = feedback_for
      feedback.add_to_errors(
        subtype: :application_error,
        details: "Task could not be queued because there were no processable items."
      )
      feedback
    end
  end
end
