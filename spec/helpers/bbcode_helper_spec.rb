require 'rails_helper'

RSpec.describe BbcodeHelper, type: :helper do
  describe "#render_bbcode" do
    it "renders bold text" do
      expect(helper.render_bbcode("[b]bold[/b]")).to include("<strong>bold</strong>")
    end

    it "renders italic text" do
      expect(helper.render_bbcode("[i]italic[/i]")).to include("<i>italic</i>")
    end

    it "renders underline text" do
      expect(helper.render_bbcode("[u]underline[/u]")).to include("<u>underline</u>")
    end

    it "renders color" do
      expect(helper.render_bbcode("[color=red]red[/color]")).to include('<span style="color: red;">red</span>')
    end

    it "renders simple url" do
      expect(helper.render_bbcode("[url]http://example.com[/url]")).to include('<a href="http://example.com" class="link-underline" target="_blank" rel="nofollow">http://example.com</a>')
    end

    it "renders named url" do
      expect(helper.render_bbcode("[url=http://example.com]Example[/url]")).to include('<a href="http://example.com" class="link-underline" target="_blank" rel="nofollow">Example</a>')
    end

    it "renders image" do
      expect(helper.render_bbcode("[img]http://example.com/image.jpg[/img]")).to include('<img src="http://example.com/image.jpg" class="max-w-full h-auto rounded my-2" />')
    end

    it "renders simple quote" do
      expect(helper.render_bbcode("[quote]text[/quote]")).to include('<div class="quote"><div class="quote-content">text</div></div>')
    end

    it "renders named quote legacy style" do
      expect(helper.render_bbcode("[quote Name]text[/quote]")).to include('<div class="quote"><div class="quote-author">Name schrieb:</div><div class="quote-content">text</div></div>')
    end

    it "renders named quote with equals" do
      expect(helper.render_bbcode("[quote=Name]text[/quote]")).to include('<div class="quote"><div class="quote-author">Name schrieb:</div><div class="quote-content">text</div></div>')
    end

    it "renders nested quotes" do
      html = helper.render_bbcode("[quote A]Outer [quote B]Inner[/quote] Tail[/quote]")
      expect(html).to include('<div class="quote-author">A schrieb:</div>')
      expect(html).to include('<div class="quote-author">B schrieb:</div>')
      expect(html).to include('Inner')
      expect(html).to include('Outer')
      expect(html).to include('Tail')
    end
    
    it "renders smileys" do
      expect(helper.render_bbcode(":) text")).to include('<img')
      expect(helper.render_bbcode(":) text")).to include('alt="fröhlich"')
      expect(helper.render_bbcode(":) text")).to include('src="/images/smileys/laechel.gif"')
    end

    it "escapes html" do
      expect(helper.render_bbcode("<script>alert('xss')</script>")).to_not include("<script>")
      expect(helper.render_bbcode("<script>alert('xss')</script>")).to include("&lt;script&gt;")
    end

    it "handles newlines" do
      expect(helper.render_bbcode("line 1\nline 2")).to include("<br />")
    end
  end
end