require 'rails_helper'

RSpec.describe UserStat, type: :model do
  let(:user) { create(:user) }
  let(:stat) { user.stat }

  describe "#rank" do
    it "returns 0 for 0 points" do
      stat.update(points: 0)
      expect(stat.rank).to eq(0)
    end

    it "returns 1 for 10 points" do
      stat.update(points: 10)
      expect(stat.rank).to eq(1)
    end

    it "returns 10 for 25000 points" do
      stat.update(points: 25000)
      expect(stat.rank).to eq(10)
    end
  end

  describe "#recalculate!" do
    it "calculates points correctly from recipes (15pts)" do
      create_list(:recipe, 2, user: user)
      stat.recalculate!
      expect(stat.points).to eq(30)
    end

    it "calculates points correctly from images (20pts)" do
      recipe = create(:recipe) # Image needs a recipe
      create(:recipe_image, :with_image, user: user, recipe: recipe)
      stat.recalculate!
      expect(stat.points).to eq(20)
    end

    it "calculates points correctly from comments (2pts)" do
      recipe = create(:recipe) # Comment needs a recipe
      create(:recipe_comment, user: user, recipe: recipe)
      stat.recalculate!
      expect(stat.points).to eq(2)
    end

    it "calculates points correctly from ratings (1pt)" do
      create(:rating, user: user, rateable: create(:recipe))
      stat.recalculate!
      expect(stat.points).to eq(1)
    end

    it "calculates points correctly from forum posts (3pts)" do
      thread = create(:forum_thread)
      create(:forum_post, user: user, forum_thread: thread)
      stat.recalculate!
      expect(stat.points).to eq(3)
    end

    it "sums up all activities" do
      create(:recipe, user: user) # 15
      create(:recipe_comment, user: user, recipe: create(:recipe)) # 2
      thread = create(:forum_thread)
      create(:forum_post, user: user, forum_thread: thread) # 3
      stat.recalculate!
      expect(stat.points).to eq(20)
    end
  end
end
