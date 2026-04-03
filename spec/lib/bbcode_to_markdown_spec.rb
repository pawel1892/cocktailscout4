require 'rails_helper'

RSpec.describe BbcodeToMarkdown do
  def convert(text)
    described_class.convert(text)
  end

  describe "bold" do
    it "converts basic bold" do
      expect(convert("[b]bold[/b]")).to eq("**bold**")
    end

    it "moves inner leading/trailing spaces outside markers" do
      expect(convert("[b] A [/b]")).to eq(" **A** ")
    end

    it "handles multiple bold tokens with spaces on one line" do
      expect(convert("[b] A [/b] | [b] B [/b]")).to eq(" **A**  |  **B** ")
    end
  end

  describe "color" do
    it "strips color tags and keeps content for visible colors" do
      expect(convert("[color=#ff0000]red text[/color]")).to eq("red text")
    end

    it "drops content entirely for near-white invisible colors" do
      expect(convert("[color=#fefefe]mmm[/color]")).to eq("")
    end

    it "drops content for other near-white colors" do
      expect(convert("[color=#fffaf0]. . . .[/color]")).to eq("")
    end
  end

  describe "italic" do
    it "converts basic italic" do
      expect(convert("[i]italic[/i]")).to eq("*italic*")
    end

    it "moves inner leading/trailing spaces outside markers" do
      expect(convert("[i] A [/i]")).to eq(" *A* ")
    end
  end
end
