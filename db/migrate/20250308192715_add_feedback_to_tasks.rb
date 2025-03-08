class AddFeedbackToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :feedback, :json
  end
end
