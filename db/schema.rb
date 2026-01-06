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

ActiveRecord::Schema[8.1].define(version: 2026_01_06_121746) do
  create_table "ingredients", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.decimal "alcoholic_content", precision: 10
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "old_id"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "ratings", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "old_id"
    t.bigint "rateable_id", null: false
    t.string "rateable_type", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["old_id"], name: "index_ratings_on_old_id"
    t.index ["rateable_type", "rateable_id"], name: "index_ratings_on_rateable"
    t.index ["user_id", "rateable_type", "rateable_id"], name: "index_ratings_on_user_id_and_rateable_type_and_rateable_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "recipe_comments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "old_id"
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["old_id"], name: "index_recipe_comments_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_comments_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_comments_on_user_id"
  end

  create_table "recipe_ingredients", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "ingredient_id", null: false
    t.integer "old_id"
    t.integer "position"
    t.bigint "recipe_id", null: false
    t.string "unit", default: "cl"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["old_id"], name: "index_recipe_ingredients_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.decimal "alcohol_content", precision: 5, scale: 2
    t.decimal "average_rating", precision: 3, scale: 1, default: "0.0"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "old_id"
    t.integer "ratings_count", default: 0
    t.string "slug"
    t.string "title", null: false
    t.decimal "total_volume", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.integer "views", default: 0
    t.index ["old_id"], name: "index_recipes_on_old_id"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_recipes_on_updated_by_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
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

  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_comments", "recipes"
  add_foreign_key "recipe_comments", "users"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "users"
  add_foreign_key "recipes", "users", column: "updated_by_id"
  add_foreign_key "sessions", "users"
end
