class CreateBatchConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :batch_configs do |t|
      t.string :batch_mode, null: false
      t.boolean :check_record_status, null: false
      t.string :date_format, null: false
      t.boolean :force_defaults, null: false
      t.string :multiple_recs_found, null: false
      t.string :null_value_string_handling, null: false
      t.string :response_mode, null: false
      t.boolean :search_if_not_cached, null: false
      t.string :status_check_method, null: false
      t.boolean :strip_id_values, null: false
      t.string :two_digit_year_handling, null: false
      t.references :activity, foreign_key: true

      t.timestamps
    end
  end
end
