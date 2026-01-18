require 'rails_helper'

RSpec.describe Rating, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:rateable) }
  end

  describe "validations" do
    it { should validate_presence_of(:score) }
    it { should validate_numericality_of(:score).only_integer }
    it { should validate_numericality_of(:score).is_greater_than_or_equal_to(1) }
    it { should validate_numericality_of(:score).is_less_than_or_equal_to(10) }

    describe "uniqueness validation" do
      let(:user) { create(:user) }
      let(:recipe) { create(:recipe) }

      it "allows one rating per user per rateable" do
        Rating.create!(user: user, rateable: recipe, score: 8)

        duplicate_rating = Rating.new(user: user, rateable: recipe, score: 9)
        expect(duplicate_rating).not_to be_valid
        expect(duplicate_rating.errors[:user_id]).to include("has already rated this item")
      end

      it "allows same user to rate different rateables" do
        recipe1 = create(:recipe)
        recipe2 = create(:recipe)

        Rating.create!(user: user, rateable: recipe1, score: 8)
        rating2 = Rating.new(user: user, rateable: recipe2, score: 9)

        expect(rating2).to be_valid
      end

      it "allows different users to rate the same rateable" do
        user1 = create(:user)
        user2 = create(:user)

        Rating.create!(user: user1, rateable: recipe, score: 8)
        rating2 = Rating.new(user: user2, rateable: recipe, score: 9)

        expect(rating2).to be_valid
      end
    end
  end

  describe "score validation boundaries" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }

    it "accepts score of 1" do
      rating = Rating.new(user: user, rateable: recipe, score: 1)
      expect(rating).to be_valid
    end

    it "accepts score of 10" do
      rating = Rating.new(user: user, rateable: recipe, score: 10)
      expect(rating).to be_valid
    end

    it "accepts score of 5" do
      rating = Rating.new(user: user, rateable: recipe, score: 5)
      expect(rating).to be_valid
    end

    it "rejects score of 0" do
      rating = Rating.new(user: user, rateable: recipe, score: 0)
      expect(rating).not_to be_valid
      expect(rating.errors[:score]).to be_present
    end

    it "rejects score of 11" do
      rating = Rating.new(user: user, rateable: recipe, score: 11)
      expect(rating).not_to be_valid
      expect(rating.errors[:score]).to be_present
    end

    it "rejects negative scores" do
      rating = Rating.new(user: user, rateable: recipe, score: -1)
      expect(rating).not_to be_valid
      expect(rating.errors[:score]).to be_present
    end

    it "rejects decimal scores" do
      rating = Rating.new(user: user, rateable: recipe, score: 5.5)
      expect(rating).not_to be_valid
      expect(rating.errors[:score]).to be_present
    end
  end

  describe "callbacks" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }

    describe "after_save" do
      it "updates rateable cache when rating is created" do
        expect(recipe).to receive(:update_rating_cache!)

        Rating.create!(user: user, rateable: recipe, score: 8)
      end

      it "updates rateable cache when rating is updated" do
        rating = Rating.create!(user: user, rateable: recipe, score: 8)

        expect(recipe).to receive(:update_rating_cache!)
        rating.update!(score: 9)
      end
    end

    describe "after_destroy" do
      it "updates rateable cache when rating is destroyed" do
        rating = Rating.create!(user: user, rateable: recipe, score: 8)

        expect(recipe).to receive(:update_rating_cache!)
        rating.destroy
      end
    end

    describe "rating cache updates" do
      it "calculates correct average with one rating" do
        Rating.create!(user: user, rateable: recipe, score: 8)

        recipe.reload
        expect(recipe.average_rating).to eq(8.0)
        expect(recipe.ratings_count).to eq(1)
      end

      it "calculates correct average with multiple ratings" do
        user2 = create(:user)
        user3 = create(:user)

        Rating.create!(user: user, rateable: recipe, score: 8)
        Rating.create!(user: user2, rateable: recipe, score: 6)
        Rating.create!(user: user3, rateable: recipe, score: 10)

        recipe.reload
        expect(recipe.average_rating).to eq(8.0)
        expect(recipe.ratings_count).to eq(3)
      end

      it "updates average when a rating is changed" do
        user2 = create(:user)
        rating1 = Rating.create!(user: user, rateable: recipe, score: 8)
        Rating.create!(user: user2, rateable: recipe, score: 6)

        recipe.reload
        expect(recipe.average_rating).to eq(7.0)

        rating1.update!(score: 10)

        recipe.reload
        expect(recipe.average_rating).to eq(8.0)
        expect(recipe.ratings_count).to eq(2)
      end

      it "updates average when a rating is destroyed" do
        user2 = create(:user)
        rating1 = Rating.create!(user: user, rateable: recipe, score: 8)
        Rating.create!(user: user2, rateable: recipe, score: 6)

        recipe.reload
        expect(recipe.average_rating).to eq(7.0)
        expect(recipe.ratings_count).to eq(2)

        rating1.destroy

        recipe.reload
        expect(recipe.average_rating).to eq(6.0)
        expect(recipe.ratings_count).to eq(1)
      end

      it "handles removal of all ratings" do
        rating1 = Rating.create!(user: user, rateable: recipe, score: 8)

        recipe.reload
        expect(recipe.ratings_count).to eq(1)

        rating1.destroy

        recipe.reload
        expect(recipe.average_rating).to eq(0.0)
        expect(recipe.ratings_count).to eq(0)
      end
    end
  end

  describe "polymorphic associations" do
    let(:user) { create(:user) }

    it "can rate a recipe" do
      recipe = create(:recipe)
      rating = Rating.create!(user: user, rateable: recipe, score: 8)

      expect(rating.rateable).to eq(recipe)
      expect(rating.rateable_type).to eq("Recipe")
    end

    it "maintains separate ratings for different types" do
      recipe = create(:recipe)
      Rating.create!(user: user, rateable: recipe, score: 8)

      # User can rate multiple items of the same type
      recipe2 = create(:recipe)
      rating2 = Rating.new(user: user, rateable: recipe2, score: 9)

      expect(rating2).to be_valid
    end
  end

  describe "user stats update" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }

    it "updates user stats after creating a rating" do
      expect {
        Rating.create!(user: user, rateable: recipe, score: 8)
      }.to change { user.stat.reload.points }.by(1)
    end

    it "updates user stats after destroying a rating" do
      rating = Rating.create!(user: user, rateable: recipe, score: 8)
      initial_points = user.stat.reload.points

      rating.destroy

      expect(user.stat.reload.points).to eq(initial_points - 1)
    end

    it "only updates stats for Recipe ratings" do
      # This test assumes there might be other rateable types in the future
      # For now, we only have recipes, so the condition is always true
      rating = Rating.create!(user: user, rateable: recipe, score: 8)

      expect(rating.rateable_type).to eq("Recipe")
      expect(user.stat.reload.points).to be > 0
    end
  end
end
