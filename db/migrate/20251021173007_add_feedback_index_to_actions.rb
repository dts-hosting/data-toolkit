class AddFeedbackIndexToActions < ActiveRecord::Migration[8.0]
  def change
    add_index :actions, :task_id,
      where: "feedback IS NOT NULL",
      name: "index_actions_on_task_id_with_feedback"
  end
end
