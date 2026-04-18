class TaskOrchestrator
  def self.action_completed(action)
    new(action).action_completed
  end

  def initialize(action)
    @action = action
    @task = action.task
  end

  def action_completed
    new_count = atomic_increment_completed
    return if new_count.nil?

    if new_count == @task.actions_count
      finalize_task
    elsif rand < @task.checkin_frequency
      @task.actions_completed_count = new_count
      broadcast_progress
    end
  end

  private

  def atomic_increment_completed
    Task.connection.select_value(
      Task.sanitize_sql([
        "UPDATE tasks SET actions_completed_count = actions_completed_count + 1, " \
        "updated_at = NOW() WHERE id = ? AND progress_status != ? " \
        "RETURNING actions_completed_count",
        @task.id, Progressable::COMPLETED
      ])
    )
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
