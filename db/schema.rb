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

ActiveRecord::Schema[8.1].define(version: 2026_03_14_123200) do
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

  create_table "env_configs", force: :cascade do |t|
    t.bigint "app_env_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["app_env_id", "kind"], name: "index_env_configs_on_app_env_id_and_kind", unique: true
    t.index ["app_env_id"], name: "index_env_configs_on_app_env_id"
  end

  create_table "variables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "value"
  end

  add_foreign_key "app_envs", "apps"
  add_foreign_key "env_configs", "app_envs"
end
