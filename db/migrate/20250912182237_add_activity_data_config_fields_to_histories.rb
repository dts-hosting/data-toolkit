class AddActivityDataConfigFieldsToHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :histories, :activity_data_config_type, :string, null: false
    add_column :histories, :activity_data_config_record_type, :string
  end
end
