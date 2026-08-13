# Builds/loads db/sample_data, a small (<50MB) committable snapshot of structural data
# (roles/units/ingredients), ~150 real recipes, ~15-20 real forum threads, and ~10 real wiki
# articles -- with authorship reassigned to 50 fabricated users so no real user PII is ever
# committed. `sample_data:export` runs on a machine with the full mirrored DB/assets;
# `sample_data:import` loads the bundle into any fresh development DB.
module SampleData
  ROOT = Rails.root.join("db/sample_data")
  DATA_DIR = ROOT.join("data")
  FILES_DIR = ROOT.join("files")

  SEED = 20260101
  PASSWORD = "password123"
  EPOCH = Time.utc(2026, 1, 1)
  SOFT_CAP_BYTES = 45 * 1024 * 1024

  USER_COUNT = 50
  RECIPE_COUNT = 150
  THREAD_COUNT = 18
  WIKI_COUNT = 10

  MAX_DIMENSION = 1000
  WIKI_HERO_DIMENSIONS = [ 1200, 800 ].freeze
  JPEG_QUALITY = 78

  # Parent-before-child load order. Reversing it gives a safe delete order too, since every
  # FK here only ever points "backwards" in this list (no forward references to defer).
  TABLES_IN_LOAD_ORDER = %w[
    roles users user_roles units forum_topics
    wiki_articles wiki_article_collaborators ingredients
    recipes recipe_ingredients tags taggings recipe_images
    forum_threads forum_images forum_posts
    recipe_comments ratings favorites
  ].freeze

  # A method, not a constant: referencing the model classes here must be deferred until the
  # rake task actually runs, since .rake files load before Rails' Zeitwerk autoloader is set up
  # (that only happens once the :environment task prerequisite runs).
  def self.model_for_table(table)
    {
      "roles" => Role, "users" => User, "user_roles" => UserRole, "units" => Unit,
      "forum_topics" => ForumTopic,
      "wiki_articles" => WikiArticle, "wiki_article_collaborators" => WikiArticleCollaborator,
      "ingredients" => Ingredient,
      "recipes" => Recipe, "recipe_ingredients" => RecipeIngredient,
      "tags" => ActsAsTaggableOn::Tag, "taggings" => ActsAsTaggableOn::Tagging,
      "recipe_images" => RecipeImage,
      "forum_threads" => ForumThread, "forum_images" => ForumImage, "forum_posts" => ForumPost,
      "recipe_comments" => RecipeComment, "ratings" => Rating, "favorites" => Favorite
    }.fetch(table)
  end

  class RoundRobin
    def initialize(items)
      @items = items
      @i = 0
    end

    def next
      item = @items[@i % @items.size]
      @i += 1
      item
    end
  end

  class SizeTracker
    attr_reader :total_bytes

    def initialize(cap_bytes)
      @cap_bytes = cap_bytes
      @total_bytes = 0
      @warned = false
    end

    def add(bytes)
      @total_bytes += bytes
      return if @warned || @total_bytes <= @cap_bytes
      @warned = true
      warn "[sample_data] bundle already #{(@total_bytes / 1.0e6).round(1)}MB, over the " \
           "#{(@cap_bytes / 1.0e6).round(1)}MB soft cap -- lower MAX_DIMENSION/JPEG_QUALITY or the sample counts"
    end
  end

  class Exporter
    def run
      raise "sample_data:export must run in development, against the mirrored DB" unless Rails.env.development?

      FileUtils.rm_rf(DATA_DIR)
      FileUtils.rm_rf(FILES_DIR)
      FileUtils.mkdir_p(DATA_DIR)
      FileUtils.mkdir_p(FILES_DIR)

      @tracker = SizeTracker.new(SOFT_CAP_BYTES)
      @notes = []

      users, user_roles = build_fake_users
      @cursor = RoundRobin.new(users.map { |u| u[:id] })

      roles = Role.order(:id).map { |r| row_of(r, %i[id name display_name old_id created_at updated_at]) }
      units = Unit.order(:id).map { |u| row_of(u, %i[id name display_name plural_name category ml_ratio divisible created_at updated_at]) }
      forum_topics = ForumTopic.order(:id).map { |t| row_of(t, %i[id name description slug position old_id created_at updated_at]) }

      wiki_ids, wiki_rows, collaborator_rows = sample_wiki
      ingredients = sample_ingredients(wiki_ids)

      recipe_ids, hero_recipe_ids, recipe_rows, recipe_ingredient_rows, tag_rows, tagging_rows, recipe_image_rows =
        sample_recipes

      thread_ids, thread_rows, post_rows, forum_image_rows = sample_forum

      comment_rows, rating_rows, favorite_rows = sample_social(recipe_ids, hero_recipe_ids)
      patch_recipe_caches!(recipe_rows, rating_rows, favorite_rows)

      write_yaml("roles", roles)
      write_yaml("users", users)
      write_yaml("user_roles", user_roles)
      write_yaml("units", units)
      write_yaml("forum_topics", forum_topics)
      write_yaml("wiki_articles", wiki_rows)
      write_yaml("wiki_article_collaborators", collaborator_rows)
      write_yaml("ingredients", ingredients)
      write_yaml("recipes", recipe_rows)
      write_yaml("recipe_ingredients", recipe_ingredient_rows)
      write_yaml("tags", tag_rows)
      write_yaml("taggings", tagging_rows)
      write_yaml("recipe_images", recipe_image_rows)
      write_yaml("forum_threads", thread_rows)
      write_yaml("forum_images", forum_image_rows)
      write_yaml("forum_posts", post_rows)
      write_yaml("recipe_comments", comment_rows)
      write_yaml("ratings", rating_rows)
      write_yaml("favorites", favorite_rows)

      write_manifest(
        row_counts: TABLES_IN_LOAD_ORDER.index_with { |t| data_row_count(t) },
        image_counts: {
          recipe_images: recipe_image_rows.size,
          forum_images: forum_image_rows.size,
          wiki_covers: wiki_rows.count { |w| FILES_DIR.join("wiki_covers", "#{w[:id]}.jpg").exist? }
        }
      )

      puts "[sample_data] export complete: #{(@tracker.total_bytes / 1.0e6).round(1)}MB in files, " \
           "#{recipe_rows.size} recipes, #{thread_rows.size} forum threads, #{wiki_rows.size} wiki articles"
      @notes.each { |n| puts "[sample_data] note: #{n}" }
    end

    private

    def data_row_count(table)
      YAML.unsafe_load_file(DATA_DIR.join("#{table}.yml")).size
    rescue Errno::ENOENT
      0
    end

    def row_of(record, columns)
      record.attributes.symbolize_keys.slice(*columns)
    end

    # Signed blob ids in mirrored production post bodies were signed with production's
    # secret_key_base, so ActiveStorage::Blob.find_signed always fails locally (mismatched
    # digest). We only need the blob id to find the ForumImage, not to trust the signature,
    # so decode the message payload directly instead of verifying it.
    def decode_blob_id(signed_id)
      payload = signed_id.to_s.split("--").first
      JSON.parse(Base64.decode64(payload)).dig("_rails", "data")
    rescue StandardError
      nil
    end

    def write_yaml(name, rows)
      File.write(DATA_DIR.join("#{name}.yml"), YAML.dump(rows))
    end

    def reencode(attached, subdir, id, max_w:, max_h: max_w)
      return unless attached.attached?
      target = FILES_DIR.join(subdir.to_s, "#{id}.jpg")
      FileUtils.mkdir_p(target.dirname)
      processor = Rails.application.config.active_storage.variant_processor == :vips ? ImageProcessing::Vips : ImageProcessing::MiniMagick
      attached.blob.open do |tempfile|
        result = processor.source(tempfile).resize_to_limit(max_w, max_h).convert("jpg").saver(quality: JPEG_QUALITY).call
        FileUtils.cp(result.path, target)
      end
      @tracker.add(File.size(target))
      true
    rescue StandardError => e
      @notes << "failed to reencode #{attached.record.class}##{attached.record_id}: #{e.message}"
      false
    end

    # --- Users -------------------------------------------------------------

    def build_fake_users
      Faker::Config.locale = "de"
      Faker::Config.random = Random.new(SEED)

      role_name_for_index = { 0 => "admin", 1 => "super_moderator" }
      %w[forum_moderator recipe_moderator image_moderator wiki_editor].each_with_index do |name, i|
        role_name_for_index[2 + (i * 2)] = name
        role_name_for_index[3 + (i * 2)] = name
      end
      role_ids_by_name = Role.pluck(:name, :id).to_h

      seen_usernames = {}
      users = []
      USER_COUNT.times do |i|
        gender = i.even? ? "m" : "w"
        prename = gender == "w" ? Faker::Name.female_first_name : Faker::Name.male_first_name
        username = nil
        loop do
          candidate = Faker::Internet.username(specifier: 5..12).gsub(/[^a-zA-Z0-9_.]/, "")
          candidate = "sampleuser#{i}" if candidate.blank?
          next if seen_usernames[candidate.downcase]
          seen_usernames[candidate.downcase] = true
          username = candidate
          break
        end

        users << {
          id: i + 1,
          username: username,
          email_address: "sample-#{username.downcase}@example.invalid",
          password_digest: BCrypt::Password.create(PASSWORD, cost: BCrypt::Engine::MIN_COST).to_s,
          prename: prename,
          gender: gender,
          homepage: nil,
          location: nil,
          public_email: nil,
          confirmation_token: nil,
          confirmation_sent_at: nil,
          confirmed_at: EPOCH,
          unconfirmed_email: nil,
          sign_in_count: 0,
          last_active_at: nil,
          last_seen_at: nil,
          old_id: nil,
          created_at: EPOCH,
          updated_at: EPOCH
        }
      end

      user_roles = role_name_for_index.map do |index, role_name|
        {
          user_id: index + 1,
          role_id: role_ids_by_name.fetch(role_name),
          old_id: nil,
          created_at: EPOCH,
          updated_at: EPOCH
        }
      end

      [ users, user_roles ]
    end

    # --- Wiki ----------------------------------------------------------------

    def sample_wiki
      featured_ids = WikiArticle.where(published: true, featured: true).order(:featured_position).limit(WIKI_COUNT).pluck(:id)
      remaining = WIKI_COUNT - featured_ids.size
      extra_ids = remaining > 0 ? WikiArticle.where(published: true).where.not(id: featured_ids).order(Arel.sql("RAND(#{SEED})")).limit(remaining).pluck(:id) : []
      wiki_ids = (featured_ids + extra_ids).uniq

      rows = WikiArticle.where(id: wiki_ids).map do |article|
        row = row_of(article, %i[id title slug body user_id last_editor_id published featured featured_position created_at updated_at])
        row[:user_id] = @cursor.next
        row[:last_editor_id] = @cursor.next if article.last_editor_id.present?
        reencode(article.cover_image, "wiki_covers", article.id, max_w: WIKI_HERO_DIMENSIONS[0], max_h: WIKI_HERO_DIMENSIONS[1])
        row
      end

      collaborator_rows = WikiArticleCollaborator.where(wiki_article_id: wiki_ids).map do |collab|
        row = row_of(collab, %i[id wiki_article_id user_id created_at updated_at])
        row[:user_id] = @cursor.next
        row
      end

      [ wiki_ids, rows, collaborator_rows ]
    end

    def sample_ingredients(wiki_ids)
      Ingredient.order(:id).map do |ingredient|
        row = row_of(ingredient, %i[id name plural_name description slug alcoholic_content ml_per_unit wiki_article_id old_id created_at updated_at])
        row[:wiki_article_id] = nil unless row[:wiki_article_id] && wiki_ids.include?(row[:wiki_article_id])
        row
      end
    end

    # --- Recipes ---------------------------------------------------------------

    def sample_recipes
      hq_ids = RecipeImage.high_quality_pool.joins(:recipe).merge(Recipe.visible).distinct.pluck(:recipe_id)
      featured_ids = RecipeImage.featured.joins(:recipe).merge(Recipe.visible).pluck(:recipe_id)
      hero_ids = Recipe.visible.where("ratings_count >= ?", Rateable::MIN_RATINGS_FOR_DISPLAY).order(ratings_count: :desc).limit(5).pluck(:id)

      forced_ids = (hq_ids.first(3) + featured_ids.first(2) + hero_ids.first(3)).uniq
      chosen = forced_ids.dup

      tag_ids = ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: { taggable_type: "Recipe" }).distinct.pluck(:id)
      tag_ids.shuffle(random: Random.new(SEED)).each do |tag_id|
        break if chosen.size >= RECIPE_COUNT
        candidate = Recipe.visible.joins(:approved_recipe_images).joins(:taggings)
          .where(taggings: { tag_id: tag_id }).where.not(id: chosen)
          .order(Arel.sql("RAND(#{SEED})")).limit(1).pick(:id)
        chosen << candidate if candidate
      end

      if chosen.size < RECIPE_COUNT
        fill = Recipe.visible.joins(:approved_recipe_images).distinct
          .where.not(id: chosen).order(Arel.sql("RAND(#{SEED})")).limit(RECIPE_COUNT - chosen.size).pluck(:id)
        chosen.concat(fill)
      end
      recipe_ids = chosen.uniq.first(RECIPE_COUNT)

      recipe_rows = []
      recipe_ingredient_rows = []
      recipe_image_rows = []

      Recipe.where(id: recipe_ids).find_each do |recipe|
        row = row_of(recipe, %i[
          id title slug description is_public is_deleted average_rating ratings_count favorites_count
          visits_count total_volume alcohol_content user_id updated_by_id old_id created_at updated_at
        ])
        row[:user_id] = @cursor.next
        row[:updated_by_id] = @cursor.next if recipe.updated_by_id.present?
        recipe_rows << row

        recipe.recipe_ingredients.each do |ri|
          recipe_ingredient_rows << row_of(ri, %i[
            id recipe_id ingredient_id unit_id unit amount additional_info description display_name
            position is_optional is_scalable needs_review old_amount old_description old_unit old_id
            created_at updated_at
          ])
        end

        image = recipe.approved_recipe_images.order(featured_at: :desc, high_quality: :desc, created_at: :desc).first ||
          recipe.recipe_images.order(created_at: :desc).first
        next unless image

        image_row = row_of(image, %i[
          id recipe_id user_id moderated_by_id state high_quality featured_at moderated_at
          moderation_reason deleted_at old_id created_at updated_at
        ])
        image_row[:user_id] = @cursor.next
        image_row[:moderated_by_id] = @cursor.next if image.moderated_by_id.present?
        if reencode(image.image, "recipe_images", image.id, max_w: MAX_DIMENSION, max_h: MAX_DIMENSION)
          recipe_image_rows << image_row
        else
          @notes << "recipe #{recipe.id} (#{recipe.slug}) had no usable image after reencode failure"
        end
      end

      recipe_ids_with_image = recipe_image_rows.map { |r| r[:recipe_id] }
      missing = recipe_ids - recipe_ids_with_image
      @notes << "#{missing.size} sampled recipes ended up without an image: #{missing.first(10)}" if missing.any?

      tagging_rows = ActsAsTaggableOn::Tagging.where(taggable_type: "Recipe", taggable_id: recipe_ids)
        .map { |t| row_of(t, %i[id tag_id taggable_id taggable_type tagger_id tagger_type context tenant created_at]) }
      tag_ids_used = tagging_rows.map { |t| t[:tag_id] }.uniq
      tag_rows = ActsAsTaggableOn::Tag.where(id: tag_ids_used).map do |tag|
        row = row_of(tag, %i[id name taggings_count created_at updated_at])
        row[:taggings_count] = tagging_rows.count { |t| t[:tag_id] == tag.id }
        row
      end

      [ recipe_ids, hero_ids & recipe_ids, recipe_rows, recipe_ingredient_rows, tag_rows, tagging_rows, recipe_image_rows ]
    end

    # --- Forum -----------------------------------------------------------------

    def sample_forum
      news_topic = ForumTopic.find_by(slug: ForumTopic::NEWS_FORUM_SLUG)
      topic_ids = ForumTopic.order(:position, :id).pluck(:id)

      candidates_by_topic = topic_ids.index_with do |topic_id|
        ForumThread.unscoped.where(forum_topic_id: topic_id, deleted: false)
          .joins("LEFT JOIN forum_posts ON forum_posts.forum_thread_id = forum_threads.id AND forum_posts.deleted = false")
          .group("forum_threads.id")
          .having("COUNT(forum_posts.id) BETWEEN 2 AND 40")
          .order(Arel.sql("MAX(forum_posts.body LIKE '%/rails/active_storage/blobs/%') DESC, RAND(#{SEED})"))
          .limit(4)
          .pluck("forum_threads.id")
      end

      thread_ids = []
      thread_ids.concat(candidates_by_topic[news_topic.id].first(2)) if news_topic

      other_topic_ids = topic_ids - [ news_topic&.id ].compact
      loop do
        added = false
        other_topic_ids.each do |topic_id|
          break if thread_ids.size >= THREAD_COUNT
          pool = candidates_by_topic[topic_id] - thread_ids
          next if pool.empty?
          thread_ids << pool.first
          added = true
        end
        break if thread_ids.size >= THREAD_COUNT || !added
      end
      thread_ids = thread_ids.first(THREAD_COUNT)

      thread_rows = ForumThread.unscoped.where(id: thread_ids).map do |thread|
        row = row_of(thread, %i[id forum_topic_id user_id title slug sticky locked deleted visits_count old_id created_at updated_at])
        row[:user_id] = @cursor.next if thread.user_id.present?
        row
      end

      posts = ForumPost.unscoped.where(forum_thread_id: thread_ids, deleted: false).order(:id).to_a
      referenced = detect_referenced_forum_images(posts)

      forum_image_rows = referenced.values.uniq(&:id).map do |image|
        row = row_of(image, %i[id user_id orphaned_at created_at updated_at])
        row[:user_id] = @cursor.next if image.user_id.present?
        row[:orphaned_at] = nil
        if reencode(image.image, "forum_images", image.id, max_w: MAX_DIMENSION, max_h: MAX_DIMENSION)
          row
        end
      end.compact
      reencoded_ids = forum_image_rows.map { |r| r[:id] }
      referenced = referenced.select { |_sid, image| reencoded_ids.include?(image.id) }

      post_rows = posts.map do |post|
        row = row_of(post, %i[id forum_thread_id user_id last_editor_id body body_bbcode deleted public_id old_id created_at updated_at])
        row[:user_id] = @cursor.next if post.user_id.present?
        row[:last_editor_id] = @cursor.next if post.last_editor_id.present?
        row[:body] = rewrite_forum_body(row[:body], referenced)
        row
      end

      [ thread_ids, thread_rows, post_rows, forum_image_rows ]
    end

    def detect_referenced_forum_images(posts)
      referenced = {}
      posts.each do |post|
        ForumImage.signed_ids_in_body(post.body.to_s).each do |sid|
          next if referenced.key?(sid)
          blob_id = decode_blob_id(sid)
          next unless blob_id
          attachment = ActiveStorage::Attachment.find_by(blob_id: blob_id, record_type: "ForumImage")
          next unless attachment
          image = ForumImage.find_by(id: attachment.record_id)
          referenced[sid] = image if image
        end
      end
      referenced
    end

    def rewrite_forum_body(body, sid_to_forum_image)
      return body if body.blank? || sid_to_forum_image.empty?
      body.gsub(ForumImage::BLOB_URL_PATTERN) do |matched|
        sid = Regexp.last_match(1)
        image = sid_to_forum_image[sid]
        image ? matched.sub(sid, "{{FORUM_IMAGE:#{image.id}}}") : matched
      end
    end

    # --- Social sample -----------------------------------------------------------

    def sample_social(recipe_ids, hero_recipe_ids)
      comment_recipe_ids = recipe_ids.sample([ 20, recipe_ids.size ].min, random: Random.new(SEED))
      comments = RecipeComment.where(recipe_id: comment_recipe_ids, parent_id: nil).order(Arel.sql("RAND(#{SEED})"))
      comment_rows = comments.group_by(&:recipe_id).flat_map { |_rid, cs| cs.first(3) }.map do |comment|
        row = row_of(comment, %i[id recipe_id user_id last_editor_id parent_id body net_votes old_id created_at updated_at])
        row[:user_id] = @cursor.next if comment.user_id.present?
        row[:last_editor_id] = @cursor.next if comment.last_editor_id.present?
        row[:net_votes] = 0
        row
      end

      rating_rows = []
      hero_recipe_ids.each do |rid|
        Rating.where(rateable_type: "Recipe", rateable_id: rid).order(Arel.sql("RAND(#{SEED})")).limit(6).each do |rating|
          row = row_of(rating, %i[id user_id rateable_type rateable_id score old_id created_at updated_at])
          row[:user_id] = @cursor.next
          rating_rows << row
        end
      end
      other_recipe_ids = (recipe_ids - hero_recipe_ids).sample(15, random: Random.new(SEED))
      other_recipe_ids.each do |rid|
        Rating.where(rateable_type: "Recipe", rateable_id: rid).order(Arel.sql("RAND(#{SEED})")).limit(2).each do |rating|
          row = row_of(rating, %i[id user_id rateable_type rateable_id score old_id created_at updated_at])
          row[:user_id] = @cursor.next
          rating_rows << row
        end
      end

      favorite_rows = []
      recipe_ids.sample([ 30, recipe_ids.size ].min, random: Random.new(SEED)).each do |rid|
        Favorite.where(favoritable_type: "Recipe", favoritable_id: rid).order(Arel.sql("RAND(#{SEED})")).limit(2).each do |favorite|
          row = row_of(favorite, %i[id user_id favoritable_type favoritable_id old_id created_at updated_at])
          row[:user_id] = @cursor.next
          favorite_rows << row
        end
      end

      [ comment_rows, rating_rows, favorite_rows ]
    end

    def patch_recipe_caches!(recipe_rows, rating_rows, favorite_rows)
      ratings_by_recipe = rating_rows.group_by { |r| r[:rateable_id] }
      favorites_by_recipe = favorite_rows.group_by { |f| f[:favoritable_id] }

      recipe_rows.each do |row|
        scores = (ratings_by_recipe[row[:id]] || []).map { |r| r[:score] }
        row[:ratings_count] = scores.size
        row[:average_rating] = scores.size >= Rateable::MIN_RATINGS_FOR_DISPLAY ? (scores.sum.to_f / scores.size).round(1) : 0.0
        row[:favorites_count] = (favorites_by_recipe[row[:id]] || []).size
      end
    end

    def write_manifest(row_counts:, image_counts:)
      manifest = {
        exported_at: Time.current.utc.iso8601,
        rng_seed: SEED,
        fake_user_password: PASSWORD,
        row_counts: row_counts,
        image_counts: image_counts,
        total_bundle_bytes: @tracker.total_bytes,
        notes: @notes
      }
      File.write(ROOT.join("manifest.json"), JSON.pretty_generate(manifest))
    end
  end

  class Importer
    def run(force: false)
      raise "sample_data:import must run in development" unless Rails.env.development?
      raise "No bundle found at #{DATA_DIR} -- run sample_data:export first" unless DATA_DIR.directory?

      non_empty = TABLES_IN_LOAD_ORDER.select { |t| SampleData.model_for_table(t).unscoped.exists? }
      if non_empty.any?
        raise "Tables not empty: #{non_empty.join(', ')}. Re-run with FORCE=true to wipe and reload." unless force
        wipe!
      end

      started = Time.current
      PaperTrail.request(enabled: false) do
        load_simple_tables!
        load_wiki!
        load_ingredients!
        load_recipes!
        load_forum!
        load_social!
      end
      recompute_recipe_caches!
      print_summary(started)
    end

    private

    def wipe!
      TABLES_IN_LOAD_ORDER.reverse_each { |t| SampleData.model_for_table(t).unscoped.delete_all }
    end

    def data(name)
      YAML.unsafe_load_file(DATA_DIR.join("#{name}.yml"))
    end

    def bulk_insert!(model, rows)
      return if rows.blank?
      rows.each_slice(500) { |batch| model.insert_all!(batch) }
    end

    def load_simple_tables!
      bulk_insert!(Role, data("roles"))
      bulk_insert!(User, data("users"))
      bulk_insert!(UserRole, data("user_roles"))
      bulk_insert!(Unit, data("units"))
      bulk_insert!(ForumTopic, data("forum_topics"))
    end

    def load_wiki!
      wiki_articles = data("wiki_articles")
      bulk_insert!(WikiArticle, wiki_articles)
      wiki_articles.each do |row|
        file = FILES_DIR.join("wiki_covers", "#{row[:id]}.jpg")
        next unless file.exist?
        WikiArticle.find(row[:id]).cover_image.attach(io: File.open(file), filename: "wiki-#{row[:id]}.jpg", content_type: "image/jpeg")
      end
      bulk_insert!(WikiArticleCollaborator, data("wiki_article_collaborators"))
    end

    def load_ingredients!
      bulk_insert!(Ingredient, data("ingredients"))
    end

    def load_recipes!
      bulk_insert!(Recipe, data("recipes"))
      bulk_insert!(RecipeIngredient, data("recipe_ingredients"))
      bulk_insert!(ActsAsTaggableOn::Tag, data("tags"))
      bulk_insert!(ActsAsTaggableOn::Tagging, data("taggings"))

      recipe_images = data("recipe_images")
      bulk_insert!(RecipeImage, recipe_images)
      recipe_images.each do |row|
        file = FILES_DIR.join("recipe_images", "#{row[:id]}.jpg")
        next unless file.exist?
        RecipeImage.find(row[:id]).image.attach(io: File.open(file), filename: "recipe-#{row[:id]}.jpg", content_type: "image/jpeg")
      end
    end

    def load_forum!
      bulk_insert!(ForumThread, data("forum_threads"))

      forum_images = data("forum_images")
      bulk_insert!(ForumImage, forum_images)
      new_signed_id_by_id = {}
      forum_images.each do |row|
        file = FILES_DIR.join("forum_images", "#{row[:id]}.jpg")
        next unless file.exist?
        image = ForumImage.find(row[:id])
        image.image.attach(io: File.open(file), filename: "forum-#{row[:id]}.jpg", content_type: "image/jpeg")
        new_signed_id_by_id[row[:id]] = image.image.blob.signed_id
      end

      posts = data("forum_posts")
      posts.each do |row|
        next if row[:body].blank?
        row[:body] = row[:body].gsub(/\{\{FORUM_IMAGE:(\d+)\}\}/) { new_signed_id_by_id[Regexp.last_match(1).to_i] || Regexp.last_match(0) }
      end
      bulk_insert!(ForumPost, posts)
    end

    def load_social!
      bulk_insert!(RecipeComment, data("recipe_comments"))
      @ratings = data("ratings")
      @favorites = data("favorites")
      bulk_insert!(Rating, @ratings)
      bulk_insert!(Favorite, @favorites)
    end

    def recompute_recipe_caches!
      touched_ids = (@ratings.map { |r| r[:rateable_id] } + @favorites.map { |f| f[:favoritable_id] }).uniq
      Recipe.where(id: touched_ids).find_each do |recipe|
        recipe.update_rating_cache!
        recipe.update_columns(favorites_count: recipe.favorites.count)
      end
    end

    def print_summary(started)
      puts "[sample_data] import complete in #{(Time.current - started).round(1)}s"
      TABLES_IN_LOAD_ORDER.each { |t| puts "  #{t}: #{SampleData.model_for_table(t).unscoped.count}" }
      manifest_path = ROOT.join("manifest.json")
      if manifest_path.exist?
        manifest = JSON.parse(File.read(manifest_path))
        puts "[sample_data] log in with password '#{manifest['fake_user_password']}' as any seeded user (see db/sample_data/data/users.yml + user_roles.yml for usernames/roles)"
      end
    end
  end
end

namespace :sample_data do
  desc "Export a small sample-data bundle (recipes, forum, wiki, users) to db/sample_data"
  task export: :environment do
    SampleData::Exporter.new.run
  end

  desc "Import db/sample_data into a fresh development DB (FORCE=true to wipe & reload)"
  task import: :environment do
    force = ActiveModel::Type::Boolean.new.cast(ENV["FORCE"])
    SampleData::Importer.new.run(force: force)
  end
end
