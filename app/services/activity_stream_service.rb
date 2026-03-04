class ActivityStreamService
  def initialize(limit: 10)
    @limit = limit
  end

  def call
    events = []
    events += forum_post_events
    events += rating_events
    events += recipe_image_events
    events += recipe_events
    events += user_events
    events += recipe_comment_events
    events.sort_by { |e| e[:created_at] }.reverse.first(@limit)
  end

  private

  def forum_post_events
    ForumPost.unscoped.where(deleted: false)
      .includes(user: :user_stat, forum_thread: [])
      .order(created_at: :desc).limit(@limit)
      .map do |post|
        { type: "forum_post", created_at: post.created_at, user: serialize_user(post.user),
          url: "/cocktailforum/beitrag/#{post.public_id}",
          meta: { thread_title: post.forum_thread&.title,
                  thread_url: post.forum_thread ? "/cocktailforum/thema/#{post.forum_thread.slug}" : nil,
                  excerpt: truncate_body(post.body, 120) } }
      end
  end

  def rating_events
    Rating.where(rateable_type: "Recipe")
      .includes(user: :user_stat, rateable: [])
      .order(updated_at: :desc).limit(@limit * 10)
      .each_with_object({}) { |r, h| h[[ r.user_id, r.rateable_id ]] ||= r }
      .values.first(@limit)
      .map do |rating|
        recipe = rating.rateable
        { type: "rating", created_at: rating.updated_at, user: serialize_user(rating.user),
          url: recipe ? "/rezepte/#{recipe.slug}/bewertungen" : nil,
          meta: { score: rating.score, recipe_title: recipe&.title,
                  recipe_url: recipe ? "/rezepte/#{recipe.slug}" : nil } }
      end
  end

  def recipe_image_events
    RecipeImage.approved.not_soft_deleted
      .includes(user: :user_stat, recipe: [])
      .order(created_at: :desc).limit(@limit)
      .map do |img|
        recipe = img.recipe
        { type: "recipe_image", created_at: img.created_at, user: serialize_user(img.user),
          url: recipe ? "/rezepte/#{recipe.slug}" : nil,
          meta: { recipe_title: recipe&.title, recipe_image_id: img.id } }
      end
  end

  def recipe_events
    Recipe.where(is_public: true, is_deleted: false)
      .includes(user: :user_stat)
      .order(created_at: :desc).limit(@limit)
      .map do |recipe|
        { type: "recipe", created_at: recipe.created_at, user: serialize_user(recipe.user),
          url: "/rezepte/#{recipe.slug}",
          meta: { recipe_title: recipe.title } }
      end
  end

  def user_events
    User.where.not(confirmed_at: nil)
      .includes(:user_stat)
      .order(confirmed_at: :desc).limit(@limit)
      .map do |user|
        { type: "user_registration", created_at: user.confirmed_at,
          user: serialize_user(user), url: nil, meta: {} }
      end
  end

  def recipe_comment_events
    RecipeComment.includes(user: :user_stat, recipe: [])
      .order(created_at: :desc).limit(@limit)
      .map do |comment|
        recipe = comment.recipe
        { type: "recipe_comment", created_at: comment.created_at, user: serialize_user(comment.user),
          url: recipe ? "/rezepte/#{recipe.slug}#kommentare" : nil,
          meta: { recipe_title: recipe&.title, recipe_url: recipe ? "/rezepte/#{recipe.slug}" : nil,
                  excerpt: truncate_body(comment.body, 120) } }
      end
  end

  def serialize_user(user)
    return { id: nil, username: "Gelöschter Benutzer", rank: nil } unless user
    { id: user.id, username: user.username, rank: user.user_stat&.rank || 0 }
  end

  def truncate_body(text, length)
    return "" if text.blank?
    text.length > length ? "#{text[0, length]}…" : text
  end
end
