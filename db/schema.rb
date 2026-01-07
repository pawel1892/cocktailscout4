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

ActiveRecord::Schema[8.1].define(version: 2026_01_07_035612) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "recipe_images", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.integer "old_id"
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved_by_id"], name: "index_recipe_images_on_approved_by_id"
    t.index ["old_id"], name: "index_recipe_images_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_images_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_images_on_user_id"
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

  create_table "taggings", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.bigint "tag_id"
    t.bigint "taggable_id"
    t.string "taggable_type"
    t.bigint "tagger_id"
    t.string "tagger_type"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", collation: "utf8mb3_bin"
    t.integer "taggings_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_comments", "recipes"
  add_foreign_key "recipe_comments", "users"
  add_foreign_key "recipe_images", "recipes"
  add_foreign_key "recipe_images", "users"
  add_foreign_key "recipe_images", "users", column: "approved_by_id"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "users"
  add_foreign_key "recipes", "users", column: "updated_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
end
