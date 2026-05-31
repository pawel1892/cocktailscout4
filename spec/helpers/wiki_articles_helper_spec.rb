require "rails_helper"

RSpec.describe WikiArticlesHelper, type: :helper do
  describe "#wiki_search_excerpt" do
    it "returns empty string for blank body" do
      expect(helper.wiki_search_excerpt("", "gin")).to eq("")
      expect(helper.wiki_search_excerpt(nil, "gin")).to eq("")
    end

    it "returns empty string for blank query" do
      expect(helper.wiki_search_excerpt("some body text", "")).to eq("")
      expect(helper.wiki_search_excerpt("some body text", nil)).to eq("")
    end

    it "wraps the matching term in a mark element" do
      result = helper.wiki_search_excerpt("Gin is a juniper spirit.", "Gin")
      expect(result).to include("<mark")
      expect(result).to include("Gin</mark>")
    end

    it "is case-insensitive when highlighting" do
      result = helper.wiki_search_excerpt("Gin is a juniper spirit.", "gin")
      expect(result).to include("<mark")
      expect(result).to include("Gin</mark>")
    end

    it "strips markdown syntax before excerpting" do
      result = helper.wiki_search_excerpt("## Gin Guide\n**Gin** is a spirit.", "Gin")
      expect(result).not_to include("##")
      expect(result).not_to include("**")
      expect(result).to include("Gin")
    end

    it "strips markdown links before excerpting" do
      result = helper.wiki_search_excerpt("See [Gin article](http://example.com) for details.", "details")
      expect(result).not_to include("http://example.com")
      expect(result).to include("Gin article")
      expect(result).not_to include("](")
    end

    it "truncates long bodies to the configured length" do
      long_body = "word " * 200
      result = helper.wiki_search_excerpt(long_body, "word", length: 50)
      expect(result.length).to be < long_body.length
    end

    it "positions the excerpt window around the match" do
      prefix = "unrelated " * 30
      body = "#{prefix}Gin is the target here."
      result = helper.wiki_search_excerpt(body, "target", length: 100)
      expect(result).to include("target")
      expect(result).to start_with("…")
    end

    it "escapes HTML in the body before highlighting" do
      result = helper.wiki_search_excerpt("<script>alert(1)</script> Gin info", "Gin")
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script")
    end
  end

  describe "#wiki_title_with_highlight" do
    it "highlights the query term in the title" do
      result = helper.wiki_title_with_highlight("Gin Guide", "Gin")
      expect(result).to include("<mark")
      expect(result).to include("Gin</mark>")
    end

    it "returns the escaped title when query is blank" do
      result = helper.wiki_title_with_highlight("Gin & Tonic", "")
      expect(result).to eq("Gin &amp; Tonic")
    end

    it "escapes HTML in the title before highlighting" do
      result = helper.wiki_title_with_highlight("<b>Gin</b> Guide", "Gin")
      expect(result).not_to include("<b>")
      expect(result).to include("&lt;b&gt;")
    end

    it "is case-insensitive" do
      result = helper.wiki_title_with_highlight("Rum History", "rum")
      expect(result).to include("<mark")
      expect(result).to include("Rum</mark>")
    end
  end
end
