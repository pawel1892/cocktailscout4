require 'rails_helper'

RSpec.describe RecipeSuggestion, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:reviewed_by).class_name('User').optional }
    it { should belong_to(:published_recipe).class_name('Recipe').optional }
    it { should have_many(:recipe_suggestion_ingredients).dependent(:destroy) }
    it { should have_many(:ingredients).through(:recipe_suggestion_ingredients) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:status) }
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq({
        "pending" => "pending",
        "approved" => "approved",
        "rejected" => "rejected"
      })
    end

    it "provides status predicate methods" do
      user = create(:user)
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Test Cocktail",
        description: "Test description",
        status: "pending"
      )

      expect(suggestion).to be_status_pending
      expect(suggestion).not_to be_status_approved
      expect(suggestion).not_to be_status_rejected
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:reviewer) { create(:user) }

    before do
      @pending = RecipeSuggestion.create!(
        user: user,
        title: "Pending Cocktail",
        description: "Description",
        status: "pending"
      )

      @approved = RecipeSuggestion.create!(
        user: user,
        title: "Approved Cocktail",
        description: "Description",
        status: "approved",
        reviewed_by: reviewer,
        reviewed_at: Time.current
      )

      @rejected = RecipeSuggestion.create!(
        user: user,
        title: "Rejected Cocktail",
        description: "Description",
        status: "rejected",
        reviewed_by: reviewer,
        reviewed_at: Time.current,
        feedback: "Not good enough"
      )
    end

    describe ".pending_review" do
      it "returns only pending suggestions" do
        expect(RecipeSuggestion.pending_review).to include(@pending)
        expect(RecipeSuggestion.pending_review).not_to include(@approved)
        expect(RecipeSuggestion.pending_review).not_to include(@rejected)
      end
    end

    describe ".reviewed" do
      it "returns approved and rejected suggestions" do
        expect(RecipeSuggestion.reviewed).to include(@approved, @rejected)
        expect(RecipeSuggestion.reviewed).not_to include(@pending)
      end
    end

    describe ".recent" do
      it "returns suggestions ordered by created_at desc" do
        results = RecipeSuggestion.recent
        expect(results.first).to eq(@rejected)  # Most recent
        expect(results.last).to eq(@pending)     # Oldest
      end
    end

    describe ".by_user" do
      it "returns suggestions for a specific user" do
        other_user = create(:user)
        other_suggestion = RecipeSuggestion.create!(
          user: other_user,
          title: "Other User Cocktail",
          description: "Description",
          status: "pending"
        )

        expect(RecipeSuggestion.by_user(user)).to include(@pending, @approved, @rejected)
        expect(RecipeSuggestion.by_user(user)).not_to include(other_suggestion)
      end
    end
  end

  describe "#editable_by?" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:reviewer) { create(:user) }

    context "when suggestion is pending" do
      it "returns true for the owner" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "pending"
        )

        expect(suggestion.editable_by?(user)).to be true
      end

      it "returns false for other users" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "pending"
        )

        expect(suggestion.editable_by?(other_user)).to be false
      end
    end

    context "when suggestion is rejected" do
      it "returns true for the owner" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "rejected",
          reviewed_by: reviewer,
          reviewed_at: Time.current,
          feedback: "Needs improvement"
        )

        expect(suggestion.editable_by?(user)).to be true
      end

      it "returns false for other users" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "rejected",
          reviewed_by: reviewer,
          reviewed_at: Time.current,
          feedback: "Needs improvement"
        )

        expect(suggestion.editable_by?(other_user)).to be false
      end
    end

    context "when suggestion is approved" do
      it "returns false for the owner" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "approved",
          reviewed_by: reviewer,
          reviewed_at: Time.current
        )

        expect(suggestion.editable_by?(user)).to be false
      end
    end

    context "when user is nil" do
      it "returns false" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "pending"
        )

        expect(suggestion.editable_by?(nil)).to be false
      end
    end
  end

  describe "#to_recipe_params" do
    let(:user) { create(:user) }
    let(:rum) { create(:ingredient, name: "Rum") }
    let(:lime) { create(:ingredient, name: "Limette") }
    let(:cl_unit) { Unit.find_by(name: "cl") || create(:unit, name: "cl", display_name: "cl", category: "volume") }

    it "converts suggestion to recipe creation params" do
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Mojito",
        description: "Classic Cuban cocktail",
        tag_list: "rum, minze, erfrischend",
        status: "pending"
      )

      suggestion.recipe_suggestion_ingredients.create!(
        ingredient: rum,
        unit: cl_unit,
        amount: 5,
        additional_info: "weiß",
        display_name: "Weißer Rum",
        is_optional: false,
        is_scalable: true,
        position: 1
      )

      suggestion.recipe_suggestion_ingredients.create!(
        ingredient: lime,
        unit: nil,
        amount: 1,
        additional_info: nil,
        display_name: nil,
        is_optional: true,
        is_scalable: false,
        position: 2
      )

      params = suggestion.to_recipe_params

      expect(params[:title]).to eq("Mojito")
      expect(params[:description]).to eq("Classic Cuban cocktail")
      expect(params[:tag_list]).to eq("rum, minze, erfrischend")
      expect(params[:is_public]).to be true

      expect(params[:ingredients_data]).to be_an(Array)
      expect(params[:ingredients_data].length).to eq(2)

      first_ingredient = params[:ingredients_data][0]
      expect(first_ingredient[:ingredient_id]).to eq(rum.id)
      expect(first_ingredient[:ingredient_name]).to eq("Rum")
      expect(first_ingredient[:unit_id]).to eq(cl_unit.id)
      expect(first_ingredient[:amount]).to eq("5.0")
      expect(first_ingredient[:additional_info]).to eq("weiß")
      expect(first_ingredient[:display_name]).to eq("Weißer Rum")
      expect(first_ingredient[:is_optional]).to be false
      expect(first_ingredient[:is_scalable]).to be true
      expect(first_ingredient[:position]).to eq(1)

      second_ingredient = params[:ingredients_data][1]
      expect(second_ingredient[:ingredient_id]).to eq(lime.id)
      expect(second_ingredient[:ingredient_name]).to eq("Limette")
      expect(second_ingredient[:unit_id]).to be_nil
      expect(second_ingredient[:amount]).to eq("1.0")
      expect(second_ingredient[:additional_info]).to be_nil
      expect(second_ingredient[:display_name]).to be_nil
      expect(second_ingredient[:is_optional]).to be true
      expect(second_ingredient[:is_scalable]).to be false
      expect(second_ingredient[:position]).to eq(2)
    end
  end

  describe "paper_trail" do
    it "tracks changes" do
      user = create(:user)
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Original Title",
        description: "Original Description",
        status: "pending"
      )

      expect(suggestion.versions.count).to be > 0

      suggestion.update!(title: "Updated Title")

      expect(suggestion.versions.count).to be > 1
    end
  end

  describe "default status" do
    it "defaults to pending" do
      user = create(:user)
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Test",
        description: "Test"
      )

      expect(suggestion.status).to eq("pending")
      expect(suggestion).to be_status_pending
    end
  end
end
