# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_05_023308) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "type", null: false
    t.integer "data_config_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "config", default: {}, null: false
    t.boolean "auto_advanced", default: true
    t.integer "data_items_count", default: 0, null: false
    t.string "label", null: false
    t.index ["data_config_id"], name: "index_activities_on_data_config_id"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "batch_configs", force: :cascade do |t|
    t.string "batch_mode", null: false
    t.boolean "check_record_status", null: false
    t.string "date_format", null: false
    t.boolean "force_defaults", null: false
    t.string "multiple_recs_found", null: false
    t.string "null_value_string_handling", null: false
    t.string "response_mode", null: false
    t.boolean "search_if_not_cached", null: false
    t.string "status_check_method", null: false
    t.boolean "strip_id_values", null: false
    t.string "two_digit_year_handling", null: false
    t.integer "activity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_batch_configs_on_activity_id"
  end

  create_table "data_configs", force: :cascade do |t|
    t.string "config_type", null: false
    t.string "profile", null: false
    t.string "version"
    t.string "record_type"
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "manifest_id", null: false
    t.index ["manifest_id", "config_type", "profile", "version", "record_type"], name: "unique_data_config_attributes", unique: true
    t.index ["manifest_id"], name: "index_data_configs_on_manifest_id"
  end

  create_table "data_items", force: :cascade do |t|
    t.json "data", null: false
    t.integer "position", default: 0, null: false
    t.integer "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.json "feedback"
    t.integer "current_task_id", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.index ["activity_id", "position"], name: "index_data_items_on_activity_id_and_position", unique: true
    t.index ["activity_id"], name: "index_data_items_on_activity_id"
    t.index ["current_task_id"], name: "index_data_items_on_current_task_id"
    t.index ["status"], name: "index_data_items_on_status"
  end

  create_table "histories", force: :cascade do |t|
    t.string "activity_user", null: false
    t.string "activity_url", null: false
    t.string "activity_type", null: false
    t.string "activity_label", null: false
    t.datetime "activity_created_at", null: false
    t.string "task_type", null: false
    t.string "task_status", null: false
    t.json "task_feedback"
    t.datetime "task_started_at"
    t.datetime "task_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_url"], name: "index_histories_on_activity_url"
    t.index ["activity_user"], name: "index_histories_on_activity_user"
  end

  create_table "manifest_registries", force: :cascade do |t|
    t.string "url", null: false
    t.datetime "last_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_manifest_registries_on_url", unique: true
  end

  create_table "manifests", force: :cascade do |t|
    t.string "url", null: false
    t.integer "manifest_registry_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_configs_count", default: 0, null: false
    t.index ["manifest_registry_id"], name: "index_manifests_on_manifest_registry_id"
    t.index ["url"], name: "index_manifests_on_url", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "type", null: false
    t.integer "activity_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "feedback"
    t.index ["activity_id"], name: "index_tasks_on_activity_id"
    t.index ["status"], name: "index_tasks_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cspace_url", null: false
    t.string "password", null: false
    t.string "cspace_api_version", null: false
    t.string "cspace_profile", null: false
    t.string "cspace_ui_version", null: false
    t.index ["email_address", "cspace_url"], name: "index_users_on_email_address_and_cspace_url", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "data_configs"
  add_foreign_key "activities", "users"
  add_foreign_key "batch_configs", "activities"
  add_foreign_key "data_configs", "manifests"
  add_foreign_key "data_items", "activities"
  add_foreign_key "data_items", "tasks", column: "current_task_id"
  add_foreign_key "manifests", "manifest_registries"
  add_foreign_key "sessions", "users"
  add_foreign_key "tasks", "activities"
end
