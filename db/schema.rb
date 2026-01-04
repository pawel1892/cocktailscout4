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

ActiveRecord::Schema[8.1].define(version: 2026_01_04_033836) do
  create_table "ingredients", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.decimal "alcoholic_content", precision: 10
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "old_id"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "gender"
    t.string "homepage"
    t.datetime "last_active_at"
    t.string "location"
    t.integer "old_id"
    t.string "password_digest", null: false
    t.string "prename"
    t.string "public_email"
    t.integer "sign_in_count"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "sessions", "users"
end
