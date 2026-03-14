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

ActiveRecord::Schema[8.1].define(version: 2026_03_14_141200) do
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

  create_table "variables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "value"
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
  add_foreign_key "environment_variables", "env_configs"
  add_foreign_key "workflow_definitions", "env_configs"
  add_foreign_key "workflow_run_steps", "workflow_runs"
  add_foreign_key "workflow_runs", "change_sets"
  add_foreign_key "workflow_runs", "env_configs"
  add_foreign_key "workflow_runs", "workflow_definitions"
end
