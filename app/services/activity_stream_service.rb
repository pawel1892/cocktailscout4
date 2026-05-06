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
      .includes(user: [ :user_stat, avatar_attachment: :blob ], forum_thread: [])
      .order(created_at: :desc).limit(@limit)
      .map do |post|
        { type: "forum_post", created_at: post.created_at, user: serialize_user(post.user),
          url: "/cocktailforum/beitrag/#{post.public_id}",
          meta: { thread_title: post.forum_thread&.title,
                  thread_url: post.forum_thread ? "/cocktailforum/thema/#{post.forum_thread.slug}" : nil,
                  excerpt: plain_text_excerpt(post.body, 120) } }
      end
  end

  def rating_events
    Rating.where(rateable_type: "Recipe")
      .includes(user: [ :user_stat, avatar_attachment: :blob ], rateable: [])
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
      .includes(user: [ :user_stat, avatar_attachment: :blob ], recipe: [])
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
      .includes(user: [ :user_stat, avatar_attachment: :blob ])
      .order(created_at: :desc).limit(@limit)
      .map do |recipe|
        { type: "recipe", created_at: recipe.created_at, user: serialize_user(recipe.user),
          url: "/rezepte/#{recipe.slug}",
          meta: { recipe_title: recipe.title } }
      end
  end

  def user_events
    User.where.not(confirmed_at: nil)
      .includes(:user_stat, avatar_attachment: :blob)
      .order(confirmed_at: :desc).limit(@limit)
      .map do |user|
        { type: "user_registration", created_at: user.confirmed_at,
          user: serialize_user(user), url: nil, meta: {} }
      end
  end

  def recipe_comment_events
    RecipeComment.includes(user: [ :user_stat, avatar_attachment: :blob ], recipe: [])
      .order(created_at: :desc).limit(@limit)
      .map do |comment|
        recipe = comment.recipe
        { type: "recipe_comment", created_at: comment.created_at, user: serialize_user(comment.user),
          url: recipe ? "/rezepte/#{recipe.slug}#kommentare" : nil,
          meta: { recipe_title: recipe&.title, recipe_url: recipe ? "/rezepte/#{recipe.slug}" : nil,
                  excerpt: plain_text_excerpt(comment.body, 120) } }
      end
  end

  def serialize_user(user)
    return { id: nil, username: "Gelöschter Benutzer", rank: nil, avatar_url_small: nil } unless user
    { id: user.id, username: user.username, rank: user.user_stat&.rank || 0,
      avatar_url_small: user.avatar_path(:small) }
  end

  SMILEY_UNICODE = {
    /:[-]?\)/    => "😊",  /:[-]?\(/    => "😢",  /;[-]?\)/   => "😉",
    /8-\)/       => "😎",  /:-p/i       => "😛",  /:cry:/i    => "😭",
    /:-?D/i      => "😄",  /:-S/i       => "😕",  /:-?O/i     => "😮",
    /:-\//       => "😕",  /:boese:/i   => "😠",  /:lol:/i    => "😂",
    /:wink:/i    => "😉",  /:party:/i   => "🎉",  /:super:/i  => "👍",
    /:hurra:/i   => "🎉",  /:stoesschen:/i => "🥂", /:ausschenken:/i => "🍸",
    /:unschuldig:/i => "😇", /:troest:/i => "🤗",  /:gelage:/i => "🍻",
    /:kater:/i   => "🤕",  /:schaem:/i  => "😳",  /:vogel:/i  => "🙄",
    /:lala:/i    => "🎵"
  }.freeze

  def plain_text_excerpt(text, length)
    return "" if text.blank?
    t = text.dup

    # Strip quote blocks (innermost first, loop for nesting)
    loop { break unless t.gsub!(/\[quote[^\]]*\].*?\[\/quote\]/mi, " ") }

    # Wikilinks → display label or ref slug
    t.gsub!(/\[\[([a-z]+):([a-zA-Z0-9\-]+)(?:\|([^\]]+))?\]\]/) do
      (Regexp.last_match(3).presence || Regexp.last_match(2)).to_s
    end

    # BBCode — strip tags, keep inner text
    t.gsub!(/\[(?:b|i|u|s)\](.*?)\[\/(?:b|i|u|s)\]/mi, '\1')
    t.gsub!(/\[color=[^\]]*\](.*?)\[\/color\]/mi, '\1')
    t.gsub!(/\[url=[^\]]*\](.*?)\[\/url\]/mi, '\1')
    t.gsub!(/\[url\](.*?)\[\/url\]/mi, '\1')
    t.gsub!(/\[(?:post|thread)[^\]]*\](.*?)\[\/(?:post|thread)\]/mi, '\1')
    t.gsub!(/\[img\].*?\[\/img\]/mi, "")

    # Smileys → Unicode emoji
    SMILEY_UNICODE.each { |pattern, emoji| t.gsub!(pattern, emoji) }
    t.gsub!(/:[a-z]+:/i, "") # strip any remaining named shortcodes

    # Markdown — strip syntax, preserve readable text
    t.gsub!(/^[#]+\s*(.+?)\s*[#]*$/, '\1') # headings (with or without trailing ###)
    t.gsub!(/\*{2}([^*\n]+)\*{2}/, '\1')   # **bold**
    t.gsub!(/\*([^*\n]+)\*/, '\1')         # *italic*
    t.gsub!(/__([^_\n]+)__/, '\1')         # __bold__
    t.gsub!(/_([^_\n]+)_/, '\1')           # _italic_
    t.gsub!(/~~([^~\n]+)~~/, '\1')         # ~~strike~~
    t.gsub!(/^>\s*/, "")                    # > blockquote prefix
    t.gsub!(/`{1,3}[^`\n]*`{1,3}/, "")    # `code`
    t.gsub!(/!\[[^\]]*\]\([^)]*\)/, "")    # ![image](url)
    t.gsub!(/\[([^\]]+)\]\([^)]*\)/, '\1') # [link](url)
    t.gsub!(/^[-*_]{3,}\s*$/, "")          # --- hr

    t.gsub!(/[[:space:]]+/, " ")
    t.strip!

    t.length > length ? "#{t[0, length]}…" : t
  end

  def truncate_body(text, length)
    return "" if text.blank?
    text.length > length ? "#{text[0, length]}…" : text
  end
end
