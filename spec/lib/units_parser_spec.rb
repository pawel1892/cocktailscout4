require "rails_helper"
require "units_parser"

RSpec.describe UnitsParser do
  describe ".parse" do
    context "with fractions" do
      it "parses 1/2 fraction" do
        result = UnitsParser.parse("1/2 Limette")
        expect(result[:amount]).to eq(0.5)
        expect(result[:unit]).to eq("x")
        expect(result[:is_garnish]).to be false
      end

      it "parses 1/4 fraction" do
        result = UnitsParser.parse("1/4 Zitrone")
        expect(result[:amount]).to eq(0.25)
        expect(result[:unit]).to eq("x")
      end

      it "parses 3/4 fraction" do
        result = UnitsParser.parse("3/4 Orange")
        expect(result[:amount]).to eq(0.75)
        expect(result[:unit]).to eq("x")
      end

      it "parses mixed numbers (1 1/2)" do
        result = UnitsParser.parse("1 1/2 Banane")
        expect(result[:amount]).to eq(1.5)
        expect(result[:unit]).to eq("x")
      end

      it "parses mixed numbers (2 1/4)" do
        result = UnitsParser.parse("2 1/4 Äpfel")
        expect(result[:amount]).to eq(2.25)
        expect(result[:unit]).to eq("x")
      end
    end

    context "with volume units" do
      it "parses cl" do
        result = UnitsParser.parse("5cl Rum")
        expect(result[:amount]).to eq(5.0)
        expect(result[:unit]).to eq("cl")
      end

      it "parses with German decimal format (comma)" do
        result = UnitsParser.parse("1,5cl Tequila")
        expect(result[:amount]).to eq(1.5)
        expect(result[:unit]).to eq("cl")
      end

      it "parses TL (Teelöffel)" do
        result = UnitsParser.parse("2 TL Zucker")
        expect(result[:amount]).to eq(2.0)
        expect(result[:unit]).to eq("tl")
      end

      it "parses EL (Esslöffel)" do
        result = UnitsParser.parse("1 EL Honig")
        expect(result[:amount]).to eq(1.0)
        expect(result[:unit]).to eq("el")
      end
    end

    context "with special units" do
      it "parses Spritzer" do
        result = UnitsParser.parse("1 Spritzer Soda")
        expect(result[:amount]).to eq(1.0)
        expect(result[:unit]).to eq("spritzer")
      end

      it "parses Dash as spritzer" do
        result = UnitsParser.parse("2 Dash Angostura")
        expect(result[:amount]).to eq(2.0)
        expect(result[:unit]).to eq("spritzer")
      end

      it "parses Splash" do
        result = UnitsParser.parse("1 Splash Soda")
        expect(result[:amount]).to eq(1.0)
        expect(result[:unit]).to eq("splash")
      end
    end

    context "with count units" do
      it "parses Scheibe" do
        result = UnitsParser.parse("1 Scheibe Zitrone")
        expect(result[:amount]).to eq(1.0)
        expect(result[:unit]).to eq("slice")
        expect(result[:is_garnish]).to be true
      end

      it "parses Scheiben (plural)" do
        result = UnitsParser.parse("2 Scheiben Orange")
        expect(result[:amount]).to eq(2.0)
        expect(result[:unit]).to eq("slice")
      end

      it "parses Zweig" do
        result = UnitsParser.parse("1 Zweig Minze")
        expect(result[:amount]).to eq(1.0)
        expect(result[:unit]).to eq("sprig")
        expect(result[:is_garnish]).to be true
      end

      it "parses Stück" do
        result = UnitsParser.parse("3 Stück Eiswürfel")
        expect(result[:amount]).to eq(3.0)
        expect(result[:unit]).to eq("piece")
      end
    end

    context "with additional info" do
      it "extracts parenthetical content" do
        result = UnitsParser.parse("5cl Rum (braun)")
        expect(result[:amount]).to eq(5.0)
        expect(result[:unit]).to eq("cl")
        expect(result[:additional_info]).to eq("braun")
      end

      it "handles descriptions without parentheses" do
        result = UnitsParser.parse("5cl Rum weiss")
        expect(result[:amount]).to eq(5.0)
        expect(result[:unit]).to eq("cl")
        expect(result[:additional_info]).to be_nil
      end
    end

    context "with unstructured data" do
      it "returns description in additional_info" do
        result = UnitsParser.parse("Minzzweig")
        expect(result[:amount]).to be_nil
        expect(result[:unit]).to be_nil
        expect(result[:additional_info]).to eq("Minzzweig")
      end

      it "detects garnishes by keywords" do
        result = UnitsParser.parse("Zur Dekoration")
        expect(result[:is_garnish]).to be true
      end
    end

    context "with ein/eine" do
      it "converts 'ein' to 1" do
        result = UnitsParser.parse("ein Spritzer Soda")
        expect(result[:amount]).to eq(1.0)
      end

      it "converts 'eine' to 1" do
        result = UnitsParser.parse("eine Scheibe Limette")
        expect(result[:amount]).to eq(1.0)
      end
    end
  end

  describe ".normalize_unit_name" do
    it "normalizes Teelöffel to tl" do
      expect(UnitsParser.normalize_unit_name("Teelöffel")).to eq("tl")
    end

    it "normalizes Esslöffel to el" do
      expect(UnitsParser.normalize_unit_name("Esslöffel")).to eq("el")
    end

    it "normalizes Dash to spritzer" do
      expect(UnitsParser.normalize_unit_name("Dash")).to eq("spritzer")
    end

    it "normalizes Scheiben to slice" do
      expect(UnitsParser.normalize_unit_name("Scheiben")).to eq("slice")
    end

    it "normalizes Blätter to leaf" do
      expect(UnitsParser.normalize_unit_name("Blätter")).to eq("leaf")
    end
  end
end
