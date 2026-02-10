module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,     # Filter raw HTML for security
      no_images: false,      # Allow images
      no_links: false,       # Allow links
      hard_wrap: true        # Convert line breaks to <br>
    )

    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,           # Auto-convert URLs to links
      tables: true,             # Support tables
      fenced_code_blocks: true, # Support ```code blocks```
      strikethrough: true,      # Support ~~strikethrough~~
      superscript: true,        # Support ^superscript^
      no_intra_emphasis: true   # Don't parse _ inside words
    )

    sanitize(markdown.render(text))  # Sanitize output to prevent XSS
  end
end
