module BbcodeHelper
  SMILEYS = [
    { name: "fröhlich", filename: "laechel.gif", expr: /:(\-)?\)/i, shortcut: ":)" },
    { name: "traurig", filename: "traurig.gif", expr: /:(\-)?\(/i, shortcut: ":(" },
    { name: "zwinker", filename: "zwinker.gif", expr: /;(\-)?\)/i, shortcut: ";)" },
    { name: "cool", filename: "cool.gif", expr: /8\-\)/i, shortcut: "8-)" },
    { name: "ätsch", filename: "aetsch.gif", expr: /:\-p/i, shortcut: ":-p" },
    { name: "weinend", filename: "heul.gif", expr: ":cry:", shortcut: ":cry:" },
    { name: "grins", filename: "grins.gif", expr: /:(\-)?D/i, shortcut: ":D" },
    { name: "verwirrt", filename: "verwirrt.gif", expr: /:\-S/i, shortcut: ":-s" },
    { name: "überrascht", filename: "ueberrascht.gif", expr: /:\-o/i, shortcut: ":-O" },
    { name: "wütend", filename: "wuetend.gif", expr: ":boese:", shortcut: ":boese:" },
    { name: "unschuldig", filename: "unschuldig.gif", expr: ":unschuldig:", shortcut: ":unschuldig:" },
    { name: "hmm", filename: "hmm.gif", expr: ":-/", shortcut: ":-/" },
    { name: "schaem.gif", filename: "schaem.gif", expr: ":schaem:", shortcut: ":schaem:" },
    { name: "ausschenken", filename: "ausschenken.gif", expr: ":ausschenken:", shortcut: ":ausschenken:" },
    { name: "hurra", filename: "hurra.gif", expr: ":hurra:", shortcut: ":hurra:" },
    { name: "lala", filename: "lala.gif", expr: ":lala:", shortcut: ":lala:" },
    { name: "lol", filename: "lol.gif", expr: ":lol:", shortcut: ":lol:" },
    { name: "party", filename: "party.gif", expr: ":party:", shortcut: ":party:" },
    { name: "stösschen", filename: "stoesschen.gif", expr: ":stoesschen:", shortcut: ":stoesschen:" },
    { name: "super", filename: "super.gif", expr: ":super:", shortcut: ":super:" },
    { name: "tröst", filename: "troest.gif", expr: ":troest:", shortcut: ":troest:" },
    { name: "vogel", filename: "vogel.gif", expr: ":vogel:", shortcut: ":vogel:" },
    { name: "wink", filename: "wink.gif", expr: ":wink:", shortcut: ":wink:" },
    { name: "gelage", filename: "gelage.gif", expr: ":gelage:", shortcut: ":gelage:" },
    { name: "kater", filename: "kater.gif", expr: ":kater:", shortcut: ":kater:" }
  ].freeze

  def render_bbcode(text)
    return "" if text.blank?

    # First, escape HTML to prevent XSS
    html = ERB::Util.html_escape(text).to_str

    # Apply BBCode tags
    html = apply_bbcode_tags(html)

    # Apply Smileys
    html = apply_smileys(html)

    # Use simple_format to handle newlines, but we already escaped HTML so we tell it not to
    simple_format(html, {}, sanitize: false)
  end

  private

  def apply_bbcode_tags(text)
    t = text.dup

    # Bold, Underline, Italic
    t.gsub!(/\[b\](.*?)\[\/b\]/mi) { "<strong>#{Regexp.last_match(1)}</strong>" }
    t.gsub!(/\[u\](.*?)\[\/u\]/mi) { "<u>#{Regexp.last_match(1)}</u>" }
    t.gsub!(/\[i\](.*?)\[\/i\]/mi) { "<i>#{Regexp.last_match(1)}</i>" }

    # Color
    t.gsub!(/\[color=(.*?)\](.*?)\[\/color\]/mi) { "<span style=\"color: #{Regexp.last_match(1)};\">#{Regexp.last_match(2)}</span>" }

    # URL
    t.gsub!(/\[url=(.*?)\](.*?)\[\/url\]/mi) { "<a href=\"#{Regexp.last_match(1)}\" class=\"link-underline\" target=\"_blank\" rel=\"nofollow\">#{Regexp.last_match(2)}</a>" }
    t.gsub!(/\[url\](.*?)\[\/url\]/mi) { "<a href=\"#{Regexp.last_match(1)}\" class=\"link-underline\" target=\"_blank\" rel=\"nofollow\">#{Regexp.last_match(1)}</a>" }

    # Post links - [post=public_id]text[/post] or [post=#public_id]text[/post]
    t.gsub!(/\[post=#?([a-zA-Z0-9]+)\](.*?)\[\/post\]/mi) do
      public_id = Regexp.last_match(1)
      link_text = Regexp.last_match(2)

      # If no custom text provided, generate default
      link_text = "Beitrag ##{public_id}" if link_text.blank?

      "<a href=\"#{show_forum_post_path(public_id)}\" " \
      "class=\"link-underline\" " \
      "title=\"Zum Beitrag\">#{link_text}</a>"
    end

    # Thread links - [thread=slug]text[/thread]
    t.gsub!(/\[thread=([a-z0-9\-]+)\](.*?)\[\/thread\]/mi) do
      thread_slug = Regexp.last_match(1)
      link_text = Regexp.last_match(2)

      # If no custom text provided, lookup thread title
      if link_text.blank?
        thread = ForumThread.find_by(slug: thread_slug)
        link_text = thread&.title || thread_slug
      end

      "<a href=\"#{forum_thread_path(thread_slug)}\" " \
      "class=\"link-underline\" " \
      "title=\"Zum Thema: #{thread_slug}\">#{link_text}</a>"
    end

    # Image
    t.gsub!(/\[img\](.*?)\[\/img\]/mi) { "<img src=\"#{Regexp.last_match(1)}\" class=\"max-w-full h-auto rounded my-2\" />" }

    # Quote with recursive support
    loop do
      found = false
      # Regex explanation:
      # \[quote            : literal [quote
      # (?:                : start optional non-capturing group for params
      #   ([^\]]*?)        : capture params (anything except ]) non-greedy
      # )?                 : end optional group
      # \]                 : literal ]
      # (                  : start capturing content
      #   (?:(?!\[quote).)*? : content that DOES NOT contain [quote
      # )                  : end capturing content
      # \[\/quote\]        : literal [/quote]
      t.gsub!(/\[quote(?:([^\]]*?))\]((?:(?!\[quote).)*?)\[\/quote\]/mi) do
        found = true
        params = Regexp.last_match(1)
        content = Regexp.last_match(2)

        render_quote_box(params, content)
      end
      break unless found
    end

    t
  end

  def render_quote_box(params, content)
    author = nil
    if params.present?
      # Clean params: "=Name" -> "Name", " Name" -> "Name"
      clean_params = params.strip
      if clean_params.start_with?("=")
        author = clean_params[1..-1]
      else
        author = clean_params
      end
    end

    author_html = author.present? ? "<div class=\"quote-author\">#{author} schrieb:</div>" : ""
    "<div class=\"quote\">#{author_html}<div class=\"quote-content\">#{content}</div></div>"
  end

  def apply_smileys(text)
    t = text.dup
    SMILEYS.each do |smiley|
      image = image_tag("/images/smileys/#{smiley[:filename]}", alt: smiley[:name], title: smiley[:shortcut], class: "inline-block align-middle")
      t.gsub!(smiley[:expr], image)
    end
    t
  end
end
