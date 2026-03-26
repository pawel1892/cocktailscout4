# Converts BBCode (as used in CocktailScout forum) to Markdown.
# Smileys are left unchanged — they use the same syntax in both formats.
# This file is self-contained and does not depend on ActiveSupport.
class BbcodeToMarkdown
  def self.convert(text)
    new(text).convert
  end

  def initialize(text)
    @text = text.dup
  end

  def convert
    t = @text.dup
    t = convert_bold(t)
    t = convert_italic(t)
    t = convert_underline(t)
    t = convert_color(t)
    t = convert_urls(t)
    t = convert_images(t)
    t = convert_post_links(t)
    t = convert_thread_links(t)
    t = convert_quotes(t)
    t
  end

  private

  def convert_bold(t)
    t.gsub(/\[b\](.*?)\[\/b\]/mi) { "**#{Regexp.last_match(1)}**" }
  end

  def convert_italic(t)
    t.gsub(/\[i\](.*?)\[\/i\]/mi) { "*#{Regexp.last_match(1)}*" }
  end

  def convert_underline(t)
    t.gsub(/\[u\](.*?)\[\/u\]/mi) { "<u>#{Regexp.last_match(1)}</u>" }
  end

  def convert_color(t)
    # Strip color tag, keep content
    t.gsub(/\[color=[^\]]*\](.*?)\[\/color\]/mi) { Regexp.last_match(1) }
  end

  def convert_urls(t)
    t = t.gsub(/\[url=([^\]]+)\](.*?)\[\/url\]/mi) { "[#{Regexp.last_match(2)}](#{Regexp.last_match(1)})" }
    t.gsub(/\[url\](.*?)\[\/url\]/mi) { "[#{Regexp.last_match(1)}](#{Regexp.last_match(1)})" }
  end

  def convert_images(t)
    t.gsub(/\[img\](.*?)\[\/img\]/mi) { "![](#{Regexp.last_match(1)})" }
  end

  def convert_post_links(t)
    t.gsub(/\[post=#?([a-zA-Z0-9]+)\](.*?)\[\/post\]/mi) do
      public_id = Regexp.last_match(1)
      link_text = Regexp.last_match(2).strip
      link_text.empty? ? "[[post:#{public_id}]]" : "[[post:#{public_id}|#{link_text}]]"
    end
  end

  def convert_thread_links(t)
    t.gsub(/\[thread=([a-z0-9\-]+)\](.*?)\[\/thread\]/mi) do
      slug      = Regexp.last_match(1)
      link_text = Regexp.last_match(2).strip
      link_text.empty? ? "[[thread:#{slug}]]" : "[[thread:#{slug}|#{link_text}]]"
    end
  end

  def convert_quotes(t)
    # Process innermost quotes first (same approach as BBCode renderer)
    loop do
      found = false
      t.gsub!(/\[quote(?:([^\]]*?))\]((?:(?!\[quote).)*?)\[\/quote\]/mi) do
        found   = true
        params  = Regexp.last_match(1)
        content = Regexp.last_match(2).strip

        author = parse_quote_author(params)

        if author
          # Keep as shortcode — renderer handles the HTML wrapping
          "[quote=#{author}]\n#{content}\n[/quote]"
        else
          content.split("\n").map { |line| "> #{line}" }.join("\n")
        end
      end
      break unless found
    end
    t
  end

  def parse_quote_author(params)
    return nil if params.nil? || params.strip.empty?
    clean = params.strip
    clean.start_with?("=") ? clean[1..] : clean
  end
end
