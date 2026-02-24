require 'rails_helper'

RSpec.describe MarkdownHelper, type: :helper do
  describe "#render_markdown" do
    it "returns empty string for nil input" do
      expect(helper.render_markdown(nil)).to eq("")
    end

    it "returns empty string for blank input" do
      expect(helper.render_markdown("")).to eq("")
    end

    it "renders headings" do
      text = "# Heading 1\n## Heading 2\n### Heading 3"
      result = helper.render_markdown(text)
      expect(result).to include("<h1>Heading 1</h1>")
      expect(result).to include("<h2>Heading 2</h2>")
      expect(result).to include("<h3>Heading 3</h3>")
    end

    it "renders bold text" do
      text = "This is **bold** text"
      result = helper.render_markdown(text)
      expect(result).to include("<strong>bold</strong>")
    end

    it "renders italic text" do
      text = "This is *italic* text"
      result = helper.render_markdown(text)
      expect(result).to include("<em>italic</em>")
    end

    it "renders lists" do
      text = "- Item 1\n- Item 2\n- Item 3"
      result = helper.render_markdown(text)
      expect(result).to include("<ul>")
      expect(result).to include("<li>Item 1</li>")
    end

    it "renders numbered lists" do
      text = "1. First\n2. Second\n3. Third"
      result = helper.render_markdown(text)
      expect(result).to include("<ol>")
      expect(result).to include("<li>First</li>")
    end

    it "renders links" do
      text = "[CocktailScout](https://cocktailscout.com)"
      result = helper.render_markdown(text)
      expect(result).to include('<a href="https://cocktailscout.com">CocktailScout</a>')
    end

    it "auto-links URLs" do
      text = "Visit https://cocktailscout.com"
      result = helper.render_markdown(text)
      expect(result).to include('<a href="https://cocktailscout.com">https://cocktailscout.com</a>')
    end

    it "renders inline code" do
      text = "Use `code` here"
      result = helper.render_markdown(text)
      expect(result).to include("<code>code</code>")
    end

    it "renders code blocks" do
      text = "```\ncode block\n```"
      result = helper.render_markdown(text)
      expect(result).to include("<code>")
      expect(result).to include("code block")
    end

    it "renders strikethrough" do
      text = "This is ~~deleted~~ text"
      result = helper.render_markdown(text)
      expect(result).to include("<del>deleted</del>")
    end

    it "sanitizes malicious HTML" do
      text = "<script>alert('XSS')</script>"
      result = helper.render_markdown(text)
      expect(result).not_to include("<script>")
      # Note: The text content "alert('XSS')" is rendered as plain text, which is safe
      expect(result).to include("alert('XSS')")
    end

    it "sanitizes malicious HTML in links" do
      text = '[Click](javascript:alert("XSS"))'
      result = helper.render_markdown(text)
      expect(result).not_to include("javascript:")
    end

    it "handles line breaks" do
      text = "Line 1\nLine 2"
      result = helper.render_markdown(text)
      expect(result).to include("<br>")
    end

    it "renders blockquotes" do
      text = "> This is a quote"
      result = helper.render_markdown(text)
      expect(result).to include("<blockquote>")
      expect(result).to include("This is a quote")
    end

    it "handles mixed formatting" do
      text = "# Title\n\nThis is **bold** and *italic* with a [link](https://example.com)"
      result = helper.render_markdown(text)
      expect(result).to include("<h1>Title</h1>")
      expect(result).to include("<strong>bold</strong>")
      expect(result).to include("<em>italic</em>")
      expect(result).to include('<a href="https://example.com">link</a>')
    end
  end
end
