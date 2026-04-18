class TaskOrchestrator
  def self.action_completed(action)
    new(action).action_completed
  end

  def initialize(action)
    @action = action
    @task = action.task
  end

  def action_completed
    row = atomic_increment_completed
    return if row.nil?

    new_count = row["actions_completed_count"]
    total = row["actions_count"]

    if new_count == total
      @task.finalize!
    elsif rand < @task.checkin_frequency
      broadcast_progress(new_count, total)
    end
  end

  private

  def atomic_increment_completed
    Task.connection.select_one(
      Task.sanitize_sql([
        "UPDATE tasks SET actions_completed_count = actions_completed_count + 1, " \
        "updated_at = NOW() " \
        "WHERE id = ? AND progress_status != ? " \
        "AND actions_completed_count < actions_count " \
        "RETURNING actions_completed_count, actions_count",
        @task.id, Progressable::COMPLETED
      ])
    )
  end

  def broadcast_progress(count, total)
    progress = total.positive? ? ((count.to_f / total) * 100).round : 0
    @action.broadcast_action_to(
      @task,
      action: :update,
      partial: "shared/card/progress",
      locals: {property: "Progress", value: progress},
      target: "task_#{@task.id}_progress"
    )
  end
end
