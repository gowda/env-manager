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

ActiveRecord::Schema[8.1].define(version: 2026_04_19_161500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_envs", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "name"], name: "index_app_envs_on_app_id_and_name", unique: true
    t.index ["app_id"], name: "index_app_envs_on_app_id"
  end

  create_table "apps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "github_repository", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["name"], name: "index_apps_on_name", unique: true
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "change_set_id"
    t.datetime "created_at", null: false
    t.bigint "env_config_id", null: false
    t.string "message", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["change_set_id"], name: "index_audit_events_on_change_set_id"
    t.index ["env_config_id", "created_at"], name: "index_audit_events_on_env_config_id_and_created_at"
    t.index ["env_config_id"], name: "index_audit_events_on_env_config_id"
  end

  create_table "change_entries", force: :cascade do |t|
    t.bigint "change_set_id", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "new_value_type"
    t.string "operation", null: false
    t.string "previous_value_type"
    t.boolean "secret", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["change_set_id", "key"], name: "index_change_entries_on_change_set_id_and_key"
    t.index ["change_set_id"], name: "index_change_entries_on_change_set_id"
  end

  create_table "change_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "env_config_id", null: false
    t.text "reason", null: false
    t.string "status", default: "applied", null: false
    t.datetime "updated_at", null: false
    t.index ["env_config_id"], name: "index_change_sets_on_env_config_id"
  end

  create_table "env_configs", force: :cascade do |t|
    t.bigint "app_env_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["app_env_id", "kind"], name: "index_env_configs_on_app_env_id_and_kind", unique: true
    t.index ["app_env_id"], name: "index_env_configs_on_app_env_id"
  end

  create_table "env_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "env_set_id", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.boolean "value_present", default: true, null: false
    t.string "value_type", default: "string", null: false
    t.index ["env_set_id", "key"], name: "index_env_items_on_env_set_id_and_key", unique: true
    t.index ["env_set_id"], name: "index_env_items_on_env_set_id"
  end

  create_table "env_sets", force: :cascade do |t|
    t.bigint "app_env_id", null: false
    t.string "category", null: false
    t.bigint "cloned_from_version_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.boolean "ui_editable", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["app_env_id", "name"], name: "index_env_sets_on_app_env_id_and_name", unique: true
    t.index ["app_env_id"], name: "index_env_sets_on_app_env_id"
    t.index ["cloned_from_version_id"], name: "index_env_sets_on_cloned_from_version_id"
  end

  create_table "environment_variables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "env_config_id", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.string "value_type", default: "single_line", null: false
    t.index ["env_config_id", "key"], name: "index_environment_variables_on_env_config_id_and_key", unique: true
    t.index ["env_config_id"], name: "index_environment_variables_on_env_config_id"
  end

  create_table "s3_set_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "env_set_id", null: false
    t.string "key_pattern", null: false
    t.string "last_sync_origin"
    t.datetime "last_synced_at"
    t.string "last_synced_checksum"
    t.string "match_kind", default: "exact", null: false
    t.string "outbound_identifier"
    t.boolean "sync_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["env_set_id"], name: "index_s3_set_mappings_on_env_set_id"
    t.index ["key_pattern"], name: "index_s3_set_mappings_prefix_like", opclass: :text_pattern_ops, where: "((match_kind)::text = 'prefix'::text)"
    t.index ["match_kind", "key_pattern"], name: "index_s3_set_mappings_on_match_kind_and_key_pattern"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "workflow_definitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.bigint "env_config_id", null: false
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["env_config_id", "kind"], name: "index_workflow_definitions_on_env_config_id_and_kind"
    t.index ["env_config_id"], name: "index_workflow_definitions_on_env_config_id"
  end

  create_table "workflow_run_steps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.bigint "workflow_run_id", null: false
    t.index ["workflow_run_id", "name"], name: "index_workflow_run_steps_on_workflow_run_id_and_name"
    t.index ["workflow_run_id"], name: "index_workflow_run_steps_on_workflow_run_id"
  end

  create_table "workflow_runs", force: :cascade do |t|
    t.bigint "change_set_id"
    t.datetime "created_at", null: false
    t.bigint "env_config_id", null: false
    t.text "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.string "status", default: "queued", null: false
    t.string "trigger_source", null: false
    t.datetime "updated_at", null: false
    t.bigint "workflow_definition_id", null: false
    t.index ["change_set_id"], name: "index_workflow_runs_on_change_set_id"
    t.index ["env_config_id", "created_at"], name: "index_workflow_runs_on_env_config_id_and_created_at"
    t.index ["env_config_id"], name: "index_workflow_runs_on_env_config_id"
    t.index ["workflow_definition_id"], name: "index_workflow_runs_on_workflow_definition_id"
  end

  add_foreign_key "app_envs", "apps"
  add_foreign_key "audit_events", "change_sets"
  add_foreign_key "audit_events", "env_configs"
  add_foreign_key "change_entries", "change_sets"
  add_foreign_key "change_sets", "env_configs"
  add_foreign_key "env_configs", "app_envs"
  add_foreign_key "env_items", "env_sets"
  add_foreign_key "env_sets", "app_envs"
  add_foreign_key "environment_variables", "env_configs"
  add_foreign_key "s3_set_mappings", "env_sets"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "workflow_definitions", "env_configs"
  add_foreign_key "workflow_run_steps", "workflow_runs"
  add_foreign_key "workflow_runs", "change_sets"
  add_foreign_key "workflow_runs", "env_configs"
  add_foreign_key "workflow_runs", "workflow_definitions"
end
