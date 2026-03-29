class BackfillTaskActionCounters < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE tasks SET
        actions_count = (SELECT COUNT(*) FROM actions WHERE actions.task_id = tasks.id),
        actions_completed_count = (
          SELECT COUNT(*) FROM actions
          WHERE actions.task_id = tasks.id
          AND actions.progress_status = 'completed'
        )
    SQL
  end

  def down
    # Counter columns dropped by rollback of add_action_counters_to_tasks
  end
end
