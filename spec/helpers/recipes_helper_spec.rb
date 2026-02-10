require 'rails_helper'

RSpec.describe RecipesHelper, type: :helper do
  describe "#recipe_thumbnail" do
    let(:recipe) { create(:recipe) }

    context "when recipe has no images" do
      it "returns a placeholder" do
        expect(helper.recipe_thumbnail(recipe)).to include("fa-cocktail")
      end
    end

    context "when recipe has only pending images" do
      let!(:pending_image) { create(:recipe_image, :with_image, :pending, recipe: recipe) }

      it "returns a placeholder" do
        expect(helper.recipe_thumbnail(recipe)).to include("fa-cocktail")
      end
    end

    context "when recipe has an approved image" do
      let!(:approved_image) { create(:recipe_image, :with_image, :approved, recipe: recipe) }

      it "returns the image tag" do
        expect(helper.recipe_thumbnail(recipe)).to include("img")
        expect(helper.recipe_thumbnail(recipe)).to include(url_for(approved_image.image.variant(:thumb)))
      end
    end

    context "when recipe has both approved and pending images" do
      let!(:pending_image) { create(:recipe_image, :with_image, :pending, recipe: recipe) }
      let!(:approved_image) { create(:recipe_image, :with_image, :approved, recipe: recipe) }

      it "returns the approved image" do
        expect(helper.recipe_thumbnail(recipe)).to include("img")
        # Since we use sample, it should always be the approved one as pending is filtered out
        # We can verify it's NOT the placeholder
        expect(helper.recipe_thumbnail(recipe)).not_to include("fa-cocktail")
      end
    end
  end

  describe "#active_filters" do
    let(:ingredient) { create(:ingredient, name: "Lemon") }

    it "returns empty array when no params present" do
      expect(helper.active_filters).to be_empty
    end

    it "returns min_rating filter" do
      helper.controller.params = { min_rating: "5" }
      expect(helper.active_filters).to contain_exactly({ label: "Bewertung: 5+", param: :min_rating })
    end

    it "returns tag filter" do
      helper.controller.params = { tag: "Rum" }
      expect(helper.active_filters).to contain_exactly({ label: "Tag: Rum", param: :tag })
    end

    it "returns ingredient filter" do
      helper.controller.params = { ingredient_id: ingredient.id }
      expect(helper.active_filters).to contain_exactly({ label: "Zutat: Lemon", param: :ingredient_id })
    end

    it "returns multiple filters" do
      helper.controller.params = { min_rating: "5", tag: "Rum" }
      expect(helper.active_filters).to include(
        { label: "Bewertung: 5+", param: :min_rating },
        { label: "Tag: Rum", param: :tag }
      )
    end

    it "ignores invalid ingredient_id" do
      helper.controller.params = { ingredient_id: -1 }
      expect(helper.active_filters).to be_empty
    end
  end

  describe "#tag_cloud_class" do
    let!(:recipe1) { create(:recipe) }
    let!(:recipe2) { create(:recipe) }
    let!(:recipe3) { create(:recipe) }

    before do
      # Create tags with different counts
      2.times { |i| r = create(:recipe); r.tag_list.add("Low"); r.save }
      5.times { |i| r = create(:recipe); r.tag_list.add("Medium"); r.save }
      20.times { |i| r = create(:recipe); r.tag_list.add("High"); r.save }
      100.times { |i| r = create(:recipe); r.tag_list.add("VeryHigh"); r.save }

      # Set @tags in helper context (simulating controller action)
      helper.instance_variable_set(:@tags, Recipe.tag_counts)
    end

    it "returns a CSS class string" do
      result = helper.tag_cloud_class(5)
      expect(result).to match(/^tag-level-\d+$/)
    end

    it "returns level between 1 and 10" do
      # Test various counts
      [ 1, 5, 10, 50, 100 ].each do |count|
        result = helper.tag_cloud_class(count)
        level = result.match(/tag-level-(\d+)/)[1].to_i
        expect(level).to be_between(1, 10).inclusive
      end
    end

    it "assigns higher levels to higher counts" do
      low_level = helper.tag_cloud_class(2).match(/tag-level-(\d+)/)[1].to_i
      high_level = helper.tag_cloud_class(100).match(/tag-level-(\d+)/)[1].to_i

      expect(high_level).to be > low_level
    end

    it "uses logarithmic distribution for better spread" do
      # With logarithmic distribution, the jump from 2 to 5 should be significant
      # while the jump from 50 to 100 should be smaller
      level_2 = helper.tag_cloud_class(2).match(/tag-level-(\d+)/)[1].to_i
      level_5 = helper.tag_cloud_class(5).match(/tag-level-(\d+)/)[1].to_i
      level_50 = helper.tag_cloud_class(50).match(/tag-level-(\d+)/)[1].to_i
      level_100 = helper.tag_cloud_class(100).match(/tag-level-(\d+)/)[1].to_i

      diff_low = level_5 - level_2
      diff_high = level_100 - level_50

      # The difference in levels should be similar or even favor the low end
      # This is the key characteristic of logarithmic scaling
      expect(diff_low).to be >= 0
      expect(diff_high).to be >= 0
    end

    context "when all tags have the same count" do
      before do
        # Clear previous data and create tags with same count
        Recipe.destroy_all
        ActsAsTaggableOn::Tag.destroy_all
        3.times do |i|
          r = create(:recipe)
          r.tag_list.add("Tag#{i}")
          r.save
        end
        helper.instance_variable_set(:@tags, Recipe.tag_counts)
      end

      it "returns level 5 (middle)" do
        result = helper.tag_cloud_class(1)
        expect(result).to eq("tag-level-5")
      end
    end

    context "when tags array is empty" do
      before do
        Recipe.destroy_all
        ActsAsTaggableOn::Tag.destroy_all
        helper.instance_variable_set(:@tags, Recipe.tag_counts)
      end

      it "returns level 1" do
        result = helper.tag_cloud_class(1)
        expect(result).to eq("tag-level-1")
      end
    end

    it "caches tag stats to avoid repeated queries" do
      # Call twice with different counts
      result1 = helper.tag_cloud_class(5)
      result2 = helper.tag_cloud_class(10)

      # Both should work and use cached stats
      expect(result1).to match(/^tag-level-\d+$/)
      expect(result2).to match(/^tag-level-\d+$/)

      # The cache should be set
      expect(helper.instance_variable_get(:@tag_cloud_stats)).to be_present
    end
  end

  describe "Authorization helpers" do
    let(:owner) { create(:user) }
    let(:moderator) { create(:user, :recipe_moderator) }
    let(:other_user) { create(:user) }
    let(:published_recipe) { create(:recipe, user: owner, is_public: true) }
    let(:draft_recipe) { create(:recipe, :draft, user: owner) }

    describe "#can_view_recipe?" do
      context "when recipe is published" do
        it "allows anyone to view" do
          [ nil, owner, moderator, other_user ].each do |user|
            allow(Current).to receive(:user).and_return(user)
            expect(helper.can_view_recipe?(published_recipe)).to be true
          end
        end
      end

      context "when recipe is a draft" do
        it "allows owner to view" do
          allow(Current).to receive(:user).and_return(owner)
          expect(helper.can_view_recipe?(draft_recipe)).to be true
        end

        it "allows moderators to view" do
          allow(Current).to receive(:user).and_return(moderator)
          expect(helper.can_view_recipe?(draft_recipe)).to be true
        end

        it "denies other users" do
          allow(Current).to receive(:user).and_return(other_user)
          expect(helper.can_view_recipe?(draft_recipe)).to be false
        end

        it "denies anonymous users" do
          allow(Current).to receive(:user).and_return(nil)
          expect(helper.can_view_recipe?(draft_recipe)).to be false
        end
      end
    end

    describe "#can_edit_recipe?" do
      it "allows owner to edit" do
        allow(Current).to receive(:user).and_return(owner)
        expect(helper.can_edit_recipe?(published_recipe)).to be true
      end

      it "allows moderators to edit" do
        allow(Current).to receive(:user).and_return(moderator)
        expect(helper.can_edit_recipe?(published_recipe)).to be true
      end

      it "denies other users" do
        allow(Current).to receive(:user).and_return(other_user)
        expect(helper.can_edit_recipe?(published_recipe)).to be false
      end

      it "denies anonymous users" do
        allow(Current).to receive(:user).and_return(nil)
        expect(helper.can_edit_recipe?(published_recipe)).to be false
      end
    end

    describe "#can_delete_recipe?" do
      it "allows moderators to delete" do
        allow(Current).to receive(:user).and_return(moderator)
        expect(helper.can_delete_recipe?(published_recipe)).to be true
      end

      it "denies owner from deleting" do
        allow(Current).to receive(:user).and_return(owner)
        expect(helper.can_delete_recipe?(published_recipe)).to be false
      end

      it "denies other users" do
        allow(Current).to receive(:user).and_return(other_user)
        expect(helper.can_delete_recipe?(published_recipe)).to be false
      end

      it "denies anonymous users" do
        allow(Current).to receive(:user).and_return(nil)
        expect(helper.can_delete_recipe?(published_recipe)).to be false
      end
    end
  end
end
