class TaskOrchestrator
  def self.action_completed(action)
    new(action).action_completed
  end

  def initialize(action)
    @action = action
    @task = action.task
  end

  def action_completed
    should_broadcast = false

    @task.with_lock do
      @task.reload
      return if @task.progress_completed?

      @task.update_column(:actions_completed_count, @task.actions_completed_count + 1)

      if ready_to_finalize?
        finalize_task
      else
        should_broadcast = rand < @task.checkin_frequency
      end
    end

    broadcast_progress if should_broadcast
  end

  private

  def ready_to_finalize?
    @task.progress_running? && @task.progress >= 100
  end

  def finalize_task
    error_count = @task.actions.with_errors.count

    outcome = if error_count == @task.actions_count
      Task::FAILED
    elsif error_count > 0 || @task.actions.with_warnings.exists?
      Task::REVIEW
    else
      Task::SUCCEEDED
    end

    @task.done!(outcome)
  end

  def broadcast_progress
    @action.broadcast_action_to(
      @task,
      action: :update,
      partial: "shared/card/progress",
      locals: {property: "Progress", value: @task.progress},
      target: "task_#{@task.id}_progress"
    )
  end
end
