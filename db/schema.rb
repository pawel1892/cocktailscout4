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

ActiveRecord::Schema[8.1].define(version: 2026_02_18_161911) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "collection_ingredients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_collection_id", null: false
    t.bigint "ingredient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_collection_id", "ingredient_id"], name: "index_collection_ingredients_on_collection_and_ingredient", unique: true
    t.index ["ingredient_collection_id"], name: "index_collection_ingredients_on_ingredient_collection_id"
    t.index ["ingredient_id", "ingredient_collection_id"], name: "index_collection_ingredients_on_ingredient_and_collection"
    t.index ["ingredient_id"], name: "index_collection_ingredients_on_ingredient_id"
  end

  create_table "favorites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "favoritable_id", null: false
    t.string "favoritable_type", null: false
    t.integer "old_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable"
    t.index ["old_id"], name: "index_favorites_on_old_id"
    t.index ["user_id", "favoritable_type", "favoritable_id"], name: "index_favorites_unique_user_favoritable", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "forum_posts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "forum_thread_id", null: false
    t.bigint "last_editor_id"
    t.integer "old_id"
    t.string "public_id", limit: 8, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["body"], name: "index_forum_posts_on_body", type: :fulltext
    t.index ["forum_thread_id"], name: "index_forum_posts_on_forum_thread_id"
    t.index ["last_editor_id"], name: "index_forum_posts_on_last_editor_id"
    t.index ["old_id"], name: "index_forum_posts_on_old_id"
    t.index ["public_id"], name: "index_forum_posts_on_public_id", unique: true
    t.index ["user_id"], name: "index_forum_posts_on_user_id"
  end

  create_table "forum_threads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "forum_topic_id", null: false
    t.boolean "locked", default: false, null: false
    t.integer "old_id"
    t.string "slug"
    t.boolean "sticky", default: false, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "visits_count", default: 0, null: false
    t.index ["forum_topic_id"], name: "index_forum_threads_on_forum_topic_id"
    t.index ["old_id"], name: "index_forum_threads_on_old_id"
    t.index ["slug"], name: "index_forum_threads_on_slug"
    t.index ["title"], name: "index_forum_threads_on_title", type: :fulltext
    t.index ["user_id"], name: "index_forum_threads_on_user_id"
  end

  create_table "forum_topics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "old_id"
    t.integer "position"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["old_id"], name: "index_forum_topics_on_old_id"
    t.index ["slug"], name: "index_forum_topics_on_slug"
  end

  create_table "ingredient_collections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_ingredient_collections_on_user_and_name", unique: true
    t.index ["user_id"], name: "index_ingredient_collections_on_user_id"
  end

  create_table "ingredients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "alcoholic_content", precision: 10
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "ml_per_unit", precision: 10, scale: 2
    t.string "name"
    t.integer "old_id"
    t.string "plural_name"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "private_messages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "deleted_by_receiver", default: false, null: false
    t.boolean "deleted_by_sender", default: false, null: false
    t.integer "old_id"
    t.boolean "read", default: false, null: false
    t.bigint "receiver_id"
    t.bigint "sender_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["old_id"], name: "index_private_messages_on_old_id"
    t.index ["receiver_id"], name: "index_private_messages_on_receiver_id"
    t.index ["sender_id"], name: "index_private_messages_on_sender_id"
  end

  create_table "ratings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "recipe_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "last_editor_id"
    t.integer "old_id"
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["last_editor_id"], name: "index_recipe_comments_on_last_editor_id"
    t.index ["old_id"], name: "index_recipe_comments_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_comments_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_comments_on_user_id"
  end

  create_table "recipe_images", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "moderated_at"
    t.bigint "moderated_by_id"
    t.text "moderation_reason"
    t.integer "old_id"
    t.bigint "recipe_id", null: false
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["moderated_by_id"], name: "index_recipe_images_on_moderated_by_id"
    t.index ["old_id"], name: "index_recipe_images_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_images_on_recipe_id"
    t.index ["state"], name: "index_recipe_images_on_state"
    t.index ["user_id"], name: "index_recipe_images_on_user_id"
  end

  create_table "recipe_ingredients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "additional_info"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "description"
    t.string "display_name"
    t.bigint "ingredient_id", null: false
    t.boolean "is_optional", default: false, null: false
    t.boolean "is_scalable", default: true, null: false
    t.boolean "needs_review", default: false, null: false
    t.decimal "old_amount", precision: 10, scale: 2
    t.string "old_description"
    t.integer "old_id"
    t.string "old_unit"
    t.integer "position"
    t.bigint "recipe_id", null: false
    t.string "unit", default: "cl"
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["is_optional"], name: "index_recipe_ingredients_on_is_optional"
    t.index ["is_scalable"], name: "index_recipe_ingredients_on_is_scalable"
    t.index ["needs_review"], name: "index_recipe_ingredients_on_needs_review"
    t.index ["old_id"], name: "index_recipe_ingredients_on_old_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
    t.index ["unit_id"], name: "index_recipe_ingredients_on_unit_id"
  end

  create_table "recipe_suggestion_ingredients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "additional_info"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "display_name"
    t.bigint "ingredient_id", null: false
    t.boolean "is_optional", default: false, null: false
    t.boolean "is_scalable", default: true, null: false
    t.integer "position", default: 0, null: false
    t.bigint "recipe_suggestion_id", null: false
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_suggestion_ingredients_on_ingredient_id"
    t.index ["position"], name: "index_recipe_suggestion_ingredients_on_position"
    t.index ["recipe_suggestion_id"], name: "index_recipe_suggestion_ingredients_on_recipe_suggestion_id"
    t.index ["unit_id"], name: "index_recipe_suggestion_ingredients_on_unit_id"
  end

  create_table "recipe_suggestions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "feedback"
    t.bigint "published_recipe_id"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.string "tag_list"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_recipe_suggestions_on_created_at"
    t.index ["published_recipe_id"], name: "index_recipe_suggestions_on_published_recipe_id"
    t.index ["reviewed_by_id"], name: "index_recipe_suggestions_on_reviewed_by_id"
    t.index ["status"], name: "index_recipe_suggestions_on_status"
    t.index ["user_id"], name: "index_recipe_suggestions_on_user_id"
  end

  create_table "recipes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "alcohol_content", precision: 5, scale: 2
    t.decimal "average_rating", precision: 3, scale: 1, default: "0.0"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_deleted", default: false, null: false
    t.boolean "is_public", default: false, null: false
    t.integer "old_id"
    t.integer "ratings_count", default: 0
    t.string "slug"
    t.string "title", null: false
    t.decimal "total_volume", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.integer "visits_count", default: 0
    t.index ["is_deleted"], name: "index_recipes_on_is_deleted"
    t.index ["is_public"], name: "index_recipes_on_is_public"
    t.index ["old_id"], name: "index_recipes_on_old_id"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
    t.index ["title"], name: "index_recipes_on_title", type: :fulltext
    t.index ["updated_by_id"], name: "index_recipes_on_updated_by_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "reports", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "old_id"
    t.integer "reason", default: 0, null: false
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.text "resolution_notes"
    t.bigint "resolved_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "name"
    t.integer "old_id"
    t.datetime "updated_at", null: false
    t.index ["old_id"], name: "index_roles_on_old_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "taggings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", collation: "utf8mb3_bin"
    t.integer "taggings_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "units", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.boolean "divisible", default: true, null: false
    t.decimal "ml_ratio", precision: 10, scale: 4
    t.string "name", null: false
    t.string "plural_name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_units_on_name", unique: true
  end

  create_table "user_roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "old_id"
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["old_id"], name: "index_user_roles_on_old_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "user_stats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "points", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_stats_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
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
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", limit: 191, null: false
    t.text "object", size: :long
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "last_visited_at"
    t.integer "old_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "visitable_id", null: false
    t.string "visitable_type", null: false
    t.index ["old_id"], name: "index_visits_on_old_id"
    t.index ["user_id"], name: "index_visits_on_user_id"
    t.index ["visitable_type", "visitable_id", "user_id"], name: "index_visits_on_visitable_and_user_id", unique: true
    t.index ["visitable_type", "visitable_id"], name: "index_visits_on_visitable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collection_ingredients", "ingredient_collections"
  add_foreign_key "collection_ingredients", "ingredients"
  add_foreign_key "favorites", "users"
  add_foreign_key "forum_posts", "forum_threads"
  add_foreign_key "forum_posts", "users"
  add_foreign_key "forum_posts", "users", column: "last_editor_id"
  add_foreign_key "forum_threads", "forum_topics"
  add_foreign_key "forum_threads", "users"
  add_foreign_key "ingredient_collections", "users"
  add_foreign_key "private_messages", "users", column: "receiver_id"
  add_foreign_key "private_messages", "users", column: "sender_id"
  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_comments", "recipes"
  add_foreign_key "recipe_comments", "users"
  add_foreign_key "recipe_comments", "users", column: "last_editor_id"
  add_foreign_key "recipe_images", "recipes"
  add_foreign_key "recipe_images", "users"
  add_foreign_key "recipe_images", "users", column: "moderated_by_id"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipe_ingredients", "units"
  add_foreign_key "recipe_suggestion_ingredients", "ingredients"
  add_foreign_key "recipe_suggestion_ingredients", "recipe_suggestions"
  add_foreign_key "recipe_suggestion_ingredients", "units"
  add_foreign_key "recipe_suggestions", "recipes", column: "published_recipe_id"
  add_foreign_key "recipe_suggestions", "users"
  add_foreign_key "recipe_suggestions", "users", column: "reviewed_by_id"
  add_foreign_key "recipes", "users"
  add_foreign_key "recipes", "users", column: "updated_by_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_stats", "users"
  add_foreign_key "visits", "users"
end
