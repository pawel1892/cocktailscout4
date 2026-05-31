module WikiArticlesHelper
  MARKDOWN_STRIP_RE = /!?\[([^\]]*)\]\([^)]*\)|\[([^\]]*)\]\[[^\]]*\]|\[\[.*?\]\]|[#*_`>~|\\]/.freeze

  def wiki_search_excerpt(body, query, length: 280)
    return "" if body.blank? || query.blank?

    plain = body.gsub(MARKDOWN_STRIP_RE) { Regexp.last_match(1) || Regexp.last_match(2) || "" }
                .gsub(/\s+/, " ").strip

    terms = query.split.map { |t| Regexp.escape(t) }
    pattern = Regexp.new(terms.first, Regexp::IGNORECASE)

    match_pos = plain.index(pattern)
    if match_pos
      start = [ match_pos - length / 3, 0 ].max
      snippet = plain[start, length]
      snippet = "…#{snippet}" if start > 0
      snippet = "#{snippet}…" if (start + length) < plain.length
    else
      snippet = plain.truncate(length)
    end

    highlighted = terms.reduce(ERB::Util.html_escape(snippet)) do |text, term|
      text.gsub(/(#{term})/i) do
        "<mark class=\"bg-cs-gold-100 text-cs-ink-900 rounded px-0.5\">#{Regexp.last_match(1)}</mark>"
      end
    end

    highlighted.html_safe
  end

  def wiki_title_with_highlight(title, query)
    return ERB::Util.html_escape(title) if query.blank?

    terms = query.split.map { |t| Regexp.escape(t) }
    highlighted = terms.reduce(ERB::Util.html_escape(title)) do |text, term|
      text.gsub(/(#{term})/i) do
        "<mark class=\"bg-cs-gold-100 text-cs-ink-900 rounded px-0.5\">#{Regexp.last_match(1)}</mark>"
      end
    end
    highlighted.html_safe
  end
end
