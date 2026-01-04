# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20121021195837280) do

  create_table "blog_entries", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "slug"
    t.string "title"
    t.text "content"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "teaser"
  end

  create_table "forum_posts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "forum_thread_id"
    t.integer "user_id"
    t.string "ip"
    t.text "content"
    t.boolean "deleted"
    t.integer "last_editor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_threads", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "forum_topic_id"
    t.integer "user_id"
    t.string "title"
    t.boolean "sticky"
    t.boolean "locked"
    t.boolean "deleted"
    t.string "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "post_count_cache"
    t.datetime "last_post_created_cache"
    t.integer "last_post_user_id_cache"
    t.index ["forum_topic_id"], name: "index_forum_threads_on_forum_topic_id"
    t.index ["last_post_created_cache"], name: "index_forum_threads_on_last_post_created_cache"
    t.index ["user_id"], name: "index_forum_threads_on_user_id"
  end

  create_table "forum_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.string "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "sorting"
    t.integer "post_count_cache"
    t.integer "thread_count_cache"
    t.integer "last_post_id_cache"
  end

  create_table "ingredients", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.decimal "alcoholic_content", precision: 3, scale: 1
  end

  create_table "private_messages", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.string "subject"
    t.text "message"
    t.boolean "read", default: false
    t.boolean "deleted_by_receiver", default: false
    t.boolean "deleted_by_sender", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "rater_id"
    t.integer "rateable_id"
    t.string "rateable_type"
    t.float "stars", limit: 24, null: false
    t.string "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rateable_id", "rateable_type"], name: "index_rates_on_rateable_id_and_rateable_type"
    t.index ["rater_id"], name: "index_rates_on_rater_id"
  end

  create_table "rating_caches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "cacheable_id"
    t.string "cacheable_type"
    t.float "avg", limit: 24, null: false
    t.integer "qty", null: false
    t.string "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cacheable_id", "cacheable_type"], name: "index_rating_caches_on_cacheable_id_and_cacheable_type"
  end

  create_table "recipe_comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "recipe_id"
    t.text "comment"
    t.string "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "guest_name"
    t.string "guest_email"
    t.integer "last_editor_id"
  end

  create_table "recipe_images", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "recipe_id"
    t.boolean "is_approved"
    t.integer "approved_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.integer "user_id"
  end

  create_table "recipe_ingredients", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "recipe_id"
    t.integer "ingredient_id"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "cl_amount", limit: 24
    t.integer "sequence"
  end

  create_table "recipes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.integer "views"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "user_id"
    t.boolean "self_created"
    t.integer "last_edit_user_id"
    t.float "cl_amount", limit: 24
    t.integer "alcoholic_content"
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "shoutbox_entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taggings", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
  end

  create_table "tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "slug"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_ingredients", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "ingredient_id"
    t.string "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_profiles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "gender"
    t.string "prename"
    t.string "public_mail"
    t.string "homepage"
    t.string "location"
    t.string "title"
    t.string "signature"
    t.text "additional_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "user_ranks", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "points"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_recipes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "recipe_id"
    t.integer "user_id"
    t.string "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "login", null: false, collation: "utf8_bin"
    t.datetime "last_active_at"
    t.integer "daily_login_count"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "api_key"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.string "tag_list"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visits", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "visitable_id"
    t.string "visitable_type"
    t.integer "user_id"
    t.integer "total_visits", default: 0
    t.datetime "last_visit_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["last_visit_time"], name: "index_visits_on_last_visit_time"
    t.index ["user_id"], name: "index_visits_on_user_id"
    t.index ["visitable_id"], name: "index_visits_on_visitable_id"
    t.index ["visitable_type"], name: "index_visits_on_visitable_type"
  end

end
