require 'rails_helper'

RSpec.describe MetaTagsHelper, type: :helper do
  describe "#default_meta_tags" do
    it "returns the default meta tags configuration" do
      tags = helper.default_meta_tags

      expect(tags[:site]).to eq("CocktailScout")
      expect(tags[:description]).to include("Entdecke und teile")
      expect(tags[:og][:site_name]).to eq("CocktailScout")
      expect(tags[:twitter][:card]).to eq("summary_large_image")
    end
  end

  describe "#set_recipe_meta_tags" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, title: "Mojito", description: "Fresh mint cocktail", user: user) }

    it "sets the correct meta tags for a recipe" do
      # We need to mock set_meta_tags as it comes from the gem
      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:title]).to eq("Mojito")
        expect(tags[:description]).to eq("Fresh mint cocktail")
        expect(tags[:og][:type]).to eq("article")
        expect(tags[:og][:title]).to eq("Mojito")
        expect(tags[:twitter][:card]).to eq("summary_large_image")
      end

      helper.set_recipe_meta_tags(recipe)
    end

    it "truncates long descriptions" do
      long_description = "A" * 200
      recipe.description = long_description

      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:description].length).to be <= 163 # 160 + "..."
      end

      helper.set_recipe_meta_tags(recipe)
    end

    it "uses the approved recipe image if available" do
      create(:recipe_image, :with_image, :approved, recipe: recipe)

      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:og][:image]).to include("/rails/active_storage/representations")
      end

      helper.set_recipe_meta_tags(recipe)
    end

    it "uses the default icon if no approved image is available" do
      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:og][:image]).to include("icon.png")
      end

      helper.set_recipe_meta_tags(recipe)
    end
  end

  describe "#set_forum_thread_meta_tags" do
    let(:topic) { create(:forum_topic, name: "General") }
    let(:thread) { create(:forum_thread, title: "Hello", forum_topic: topic) }

    it "sets meta tags using the first post body" do
      create(:forum_post, forum_thread: thread, body: "This is the first post")

      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:title]).to eq("Hello")
        expect(tags[:description]).to eq("This is the first post")
        expect(tags[:og][:type]).to eq("article")
      end

      helper.set_forum_thread_meta_tags(thread)
    end

    it "sets default description if no posts exist" do
      expect(helper).to receive(:set_meta_tags) do |tags|
        expect(tags[:description]).to include("General - Diskussion")
      end

      helper.set_forum_thread_meta_tags(thread)
    end
  end
end
