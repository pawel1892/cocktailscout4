module MarkdownHelper
  MARKDOWN_ALLOWED_TAGS = %w[
    p br strong em u del s blockquote figure figcaption
    a img ul ol li pre code h1 h2 h3 h4 h5 h6
    table thead tbody tr th td
  ].freeze

  # Rails sanitize() takes a flat list of allowed attribute names (not per-tag)
  MARKDOWN_ALLOWED_ATTRIBUTES = %w[href src alt title class rel target].freeze

  # Wikilink pattern: [[type:ref]] or [[type:ref|Custom Text]]
  WIKILINK_PATTERN = /\[\[([a-z]+):([a-zA-Z0-9\-]+)(?:\|([^\]]+))?\]\]/

  def render_markdown(text)
    return "" if text.blank?

    html = rich_markdown_renderer.render(preprocess_markdown_shortcodes(text))
    html = apply_markdown_smileys(html)
    sanitize(html, tags: MARKDOWN_ALLOWED_TAGS, attributes: MARKDOWN_ALLOWED_ATTRIBUTES)
  end

  private

  def rich_markdown_renderer
    @rich_markdown_renderer ||= Redcarpet::Markdown.new(
      RichHtmlRenderer.new(filter_html: false, hard_wrap: true),
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      no_intra_emphasis: true
    )
  end

  def preprocess_markdown_shortcodes(text)
    t = text.dup

    # Wikilinks: [[recipe:slug]], [[recipe:slug|Custom Text]],
    #            [[thread:slug]], [[thread:slug|Custom Text]],
    #            [[post:public_id]], [[post:public_id|Custom Text]]
    t.gsub!(WIKILINK_PATTERN) do
      type = Regexp.last_match(1)
      ref  = Regexp.last_match(2)
      custom_text = Regexp.last_match(3)

      case type
      when "recipe"
        r = Recipe.find_by(slug: ref)
        label = custom_text.presence || r&.title || ref
        "[#{label}](#{recipe_path(ref)})"
      when "thread"
        thread = ForumThread.find_by(slug: ref)
        label = custom_text.presence || thread&.title || ref
        "[#{label}](#{forum_thread_path(ref)})"
      when "post"
        label = custom_text.presence || "Beitrag \##{ref}"
        "[#{label}](#{show_forum_post_path(ref)})"
      else
        Regexp.last_match(0) # unknown type: leave unchanged
      end
    end

    # Quotes — process innermost first
    loop do
      found = false
      t.gsub!(/\[quote(?:=([^\]]*))?\]((?:(?!\[quote).)*?)\[\/quote\]/mi) do
        found = true
        author  = Regexp.last_match(1)&.strip
        content = Regexp.last_match(2)

        if author.present?
          author_escaped = ERB::Util.html_escape(author)
          %(<figure class="md-quote"><figcaption>#{author_escaped} schrieb:</figcaption><blockquote>#{content.strip}</blockquote></figure>)
        else
          content.strip.split("\n").map { |l| "> #{l}" }.join("\n")
        end
      end
      break unless found
    end

    t
  end

  def apply_markdown_smileys(html)
    t = html.dup
    BbcodeHelper::SMILEYS.each do |s|
      img = %(<img src="/images/smileys/#{s[:filename]}" alt="#{ERB::Util.html_escape(s[:name])}" title="#{ERB::Util.html_escape(s[:shortcut])}" class="inline-block align-middle h-5 w-auto">)
      t.gsub!(s[:expr], img)
    end
    t
  end

  class RichHtmlRenderer < Redcarpet::Render::HTML
    def link(link, title, content)
      title_attr = title ? %( title="#{ERB::Util.html_escape(title)}") : ""
      external   = !link.to_s.start_with?("/")
      ext_attrs  = external ? ' rel="nofollow noopener" target="_blank"' : ""
      %(<a href="#{ERB::Util.html_escape(link.to_s)}"#{title_attr} class="link-underline"#{ext_attrs}>#{content}</a>)
    end

    def image(link, title, alt)
      title_attr = title ? %( title="#{ERB::Util.html_escape(title)}") : ""
      %(<img src="#{ERB::Util.html_escape(link.to_s)}" alt="#{ERB::Util.html_escape(alt.to_s)}"#{title_attr} class="max-w-full h-auto rounded my-2">)
    end
  end
end
