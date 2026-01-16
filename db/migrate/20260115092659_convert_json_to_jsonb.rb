class ConvertJsonToJsonb < ActiveRecord::Migration[8.1]
  def up
    change_column :actions, :feedback, :jsonb
    change_column :activities, :config, :jsonb, default: {}, null: false
    change_column :data_items, :data, :jsonb, null: false
    change_column :histories, :task_feedback, :jsonb
    change_column :tasks, :feedback, :jsonb
  end

  def down
    change_column :actions, :feedback, :json
    change_column :activities, :config, :json, default: {}, null: false
    change_column :data_items, :data, :json, null: false
    change_column :histories, :task_feedback, :json
    change_column :tasks, :feedback, :json
  end
end
