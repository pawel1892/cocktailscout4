require 'rails_helper'

RSpec.describe NavigationHelper, type: :helper do
  describe "#main_navigation_items" do
    it "returns an array of navigation items" do
      items = helper.main_navigation_items

      expect(items).to be_an(Array)
      expect(items.length).to eq(3)
    end

    it "includes Rezepte navigation item" do
      items = helper.main_navigation_items
      rezepte_item = items.find { |item| item[:label] == "Rezepte" }

      expect(rezepte_item).to be_present
      expect(rezepte_item[:path]).to eq(recipes_path)
      expect(rezepte_item[:dropdown]).to be_present
      expect(rezepte_item[:controllers]).to include('recipes', 'recipe_images')
    end

    it "includes Community navigation item" do
      items = helper.main_navigation_items
      community_item = items.find { |item| item[:label] == "Community" }

      expect(community_item).to be_present
      expect(community_item[:path]).to eq(community_path)
      expect(community_item[:dropdown]).to be_present
      expect(community_item[:controllers]).to include('users', 'forum_topics', 'forum_threads', 'forum_posts')
    end

    it "includes Meine Bar navigation item" do
      items = helper.main_navigation_items
      bar_item = items.find { |item| item[:label] == "Meine Bar" }

      expect(bar_item).to be_present
      expect(bar_item[:path]).to eq(my_bar_path)
      expect(bar_item[:dropdown]).to be_nil
    end

    it "Rezepte dropdown includes correct items" do
      items = helper.main_navigation_items
      rezepte_item = items.find { |item| item[:label] == "Rezepte" }

      expect(rezepte_item[:dropdown].length).to eq(4)
      expect(rezepte_item[:dropdown][0][:label]).to eq("Alle Rezepte")
      expect(rezepte_item[:dropdown][1][:label]).to eq("Cocktailgalerie")
      expect(rezepte_item[:dropdown][2][:label]).to eq("Toplisten")
      expect(rezepte_item[:dropdown][3][:label]).to eq("Rezept-Kategorien")
    end

    it "Community dropdown includes correct items" do
      items = helper.main_navigation_items
      community_item = items.find { |item| item[:label] == "Community" }

      expect(community_item[:dropdown].length).to eq(3)
      expect(community_item[:dropdown][0][:label]).to eq("Übersicht")
      expect(community_item[:dropdown][1][:label]).to eq("Forum")
      expect(community_item[:dropdown][2][:label]).to eq("Benutzer")
    end
  end

  describe "#current_nav_item" do
    context "when on recipes controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipes')
        allow(helper).to receive(:controller_path).and_return('recipes')
      end

      it "returns the Rezepte navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Rezepte")
      end
    end

    context "when on recipe_images controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipe_images')
        allow(helper).to receive(:controller_path).and_return('recipe_images')
      end

      it "returns the Rezepte navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Rezepte")
      end
    end

    context "when on recipe_categories controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipe_categories')
        allow(helper).to receive(:controller_path).and_return('recipe_categories')
      end

      it "returns the Rezepte navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Rezepte")
      end
    end

    context "when on top_lists controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('top_lists')
        allow(helper).to receive(:controller_path).and_return('top_lists')
      end

      it "returns the Rezepte navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Rezepte")
      end
    end

    context "when on users controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('users')
        allow(helper).to receive(:controller_path).and_return('users')
      end

      it "returns the Community navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Community")
      end
    end

    context "when on forum_topics controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('forum_topics')
        allow(helper).to receive(:controller_path).and_return('forum_topics')
      end

      it "returns the Community navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Community")
      end
    end

    context "when on my_bar controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('my_bar')
        allow(helper).to receive(:controller_path).and_return('my_bar')
      end

      it "returns the Meine Bar navigation item" do
        item = helper.current_nav_item

        expect(item[:label]).to eq("Meine Bar")
      end
    end

    context "when on unrelated controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('sessions')
        allow(helper).to receive(:controller_path).and_return('sessions')
      end

      it "returns nil" do
        expect(helper.current_nav_item).to be_nil
      end
    end
  end

  describe "#show_subnav?" do
    context "when current item has dropdown" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipes')
        allow(helper).to receive(:controller_path).and_return('recipes')
      end

      it "returns true" do
        expect(helper.show_subnav?).to be true
      end
    end

    context "when current item has no dropdown" do
      before do
        allow(helper).to receive(:controller_name).and_return('my_bar')
        allow(helper).to receive(:controller_path).and_return('my_bar')
      end

      it "returns false" do
        expect(helper.show_subnav?).to be false
      end
    end

    context "when no current item" do
      before do
        allow(helper).to receive(:controller_name).and_return('sessions')
        allow(helper).to receive(:controller_path).and_return('sessions')
      end

      it "returns false" do
        expect(helper.show_subnav?).to be false
      end
    end
  end

  describe "#subnav_items" do
    context "when on recipes controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipes')
        allow(helper).to receive(:controller_path).and_return('recipes')
      end

      it "returns the Rezepte dropdown items" do
        items = helper.subnav_items

        expect(items).to be_an(Array)
        expect(items.length).to eq(4)
        expect(items[0][:label]).to eq("Alle Rezepte")
        expect(items[1][:label]).to eq("Cocktailgalerie")
        expect(items[2][:label]).to eq("Toplisten")
        expect(items[3][:label]).to eq("Rezept-Kategorien")
      end
    end

    context "when on forum controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('forum_topics')
        allow(helper).to receive(:controller_path).and_return('forum_topics')
      end

      it "returns the Community dropdown items" do
        items = helper.subnav_items

        expect(items).to be_an(Array)
        expect(items.length).to eq(3)
        expect(items[0][:label]).to eq("Übersicht")
        expect(items[1][:label]).to eq("Forum")
        expect(items[2][:label]).to eq("Benutzer")
      end
    end

    context "when on controller with no dropdown" do
      before do
        allow(helper).to receive(:controller_name).and_return('my_bar')
        allow(helper).to receive(:controller_path).and_return('my_bar')
      end

      it "returns empty array" do
        items = helper.subnav_items

        expect(items).to eq([])
      end
    end
  end

  describe "#subnav_item_active?" do
    context "when on recipes controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipes')
        allow(helper).to receive(:controller_path).and_return('recipes')
      end

      it "marks 'Alle Rezepte' as active" do
        item = { label: "Alle Rezepte", controllers: [ 'recipes' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end

      it "does not mark 'Cocktailgalerie' as active" do
        item = { label: "Cocktailgalerie", controllers: [ 'recipe_images' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end
    end

    context "when on recipe_images controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipe_images')
        allow(helper).to receive(:controller_path).and_return('recipe_images')
      end

      it "marks 'Cocktailgalerie' as active" do
        item = { label: "Cocktailgalerie", controllers: [ 'recipe_images' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end

      it "does not mark 'Alle Rezepte' as active" do
        item = { label: "Alle Rezepte", controllers: [ 'recipes' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end
    end

    context "when on recipe_categories controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('recipe_categories')
        allow(helper).to receive(:controller_path).and_return('recipe_categories')
      end

      it "marks 'Rezept-Kategorien' as active" do
        item = { label: "Rezept-Kategorien", controllers: [ 'recipe_categories' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end

      it "does not mark 'Alle Rezepte' as active" do
        item = { label: "Alle Rezepte", controllers: [ 'recipes' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end

      it "does not mark 'Cocktailgalerie' as active" do
        item = { label: "Cocktailgalerie", controllers: [ 'recipe_images' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end
    end

    context "when on top_lists controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('top_lists')
        allow(helper).to receive(:controller_path).and_return('top_lists')
      end

      it "marks 'Toplisten' as active" do
        item = { label: "Toplisten", controllers: [ 'top_lists' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end

      it "does not mark 'Alle Rezepte' as active" do
        item = { label: "Alle Rezepte", controllers: [ 'recipes' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end
    end

    context "when on users controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('users')
        allow(helper).to receive(:controller_path).and_return('users')
      end

      it "marks 'Benutzer' as active" do
        item = { label: "Benutzer", controllers: [ 'users' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end

      it "does not mark 'Forum' as active" do
        item = { label: "Forum", controllers: [ 'forum_topics', 'forum_threads' ] }

        expect(helper.subnav_item_active?(item)).to be false
      end
    end

    context "when on forum_threads controller" do
      before do
        allow(helper).to receive(:controller_name).and_return('forum_threads')
        allow(helper).to receive(:controller_path).and_return('forum_threads')
      end

      it "marks 'Forum' as active" do
        item = { label: "Forum", controllers: [ 'forum_topics', 'forum_threads', 'forum_posts' ] }

        expect(helper.subnav_item_active?(item)).to be true
      end
    end
  end
end
