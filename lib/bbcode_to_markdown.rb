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
    t.gsub(/\[b\](.*?)\[\/b\]/mi) do
      inner = Regexp.last_match(1)
      "#{inner[/\A\s*/]}**#{inner.strip}**#{inner[/\s*\z/]}"
    end
  end

  def convert_italic(t)
    t.gsub(/\[i\](.*?)\[\/i\]/mi) do
      inner = Regexp.last_match(1)
      "#{inner[/\A\s*/]}*#{inner.strip}*#{inner[/\s*\z/]}"
    end
  end

  def convert_underline(t)
    t.gsub(/\[u\](.*?)\[\/u\]/mi) { "<u>#{Regexp.last_match(1)}</u>" }
  end

  def convert_color(t)
    t.gsub(/\[color=([^\]]*)\](.*?)\[\/color\]/mi) do
      invisible_color?(Regexp.last_match(1)) ? "" : Regexp.last_match(2)
    end
  end

  def invisible_color?(color)
    hex = color.strip.delete("#")
    return false unless hex.match?(/\A[0-9a-f]{6}\z/i)
    r = hex[0, 2].to_i(16)
    g = hex[2, 2].to_i(16)
    b = hex[4, 2].to_i(16)
    r > 200 && g > 200 && b > 200
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
    # Process innermost quotes first. Authored quotes output a shortcode that
    # would re-match the same regex, so we replace them with sentinel tokens
    # during the loop and restore after all anonymous quotes are resolved.
    authored = []

    loop do
      found = false
      t.gsub!(/\[quote(?:[= ]([^\]]*?))?\s*\]((?:(?!\[quote).)*?)\[\/quote\]/mi) do
        found   = true
        author  = Regexp.last_match(1)&.strip
        content = Regexp.last_match(2).strip

        if author && !author.empty?
          token = "QSENT#{authored.length}QSENT"
          authored << "[quote=#{author}]\n#{content}\n[/quote]"
          token
        else
          content.split("\n").map { |line| "> #{line}" }.join("\n")
        end
      end
      break unless found
    end

    # Restore sentinels in reverse insertion order (outer quotes contain
    # inner sentinel tokens, so restore inner first).
    (authored.length - 1).downto(0) do |idx|
      t.gsub!("QSENT#{idx}QSENT", authored[idx])
    end
    t
  end
end
