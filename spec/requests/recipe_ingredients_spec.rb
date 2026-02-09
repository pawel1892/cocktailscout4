require 'rails_helper'

RSpec.describe "Recipe Ingredients API", type: :request do
  let(:recipe) { create(:recipe, slug: 'mojito') }
  let(:unit_cl) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }
  let(:unit_piece) { Unit.find_or_create_by!(name: "piece") { |u| u.display_name = "Stück"; u.plural_name = "Stück"; u.category = "count"; u.ml_ratio = nil; u.divisible = false } }
  let(:unit_blank) { Unit.find_or_create_by!(name: "x") { |u| u.display_name = ""; u.plural_name = ""; u.category = "count"; u.ml_ratio = nil; u.divisible = true } }

  let!(:ingredient_rum) { create(:ingredient, name: "Rum (weiss)") }
  let!(:ingredient_lime) { create(:ingredient, name: "Limette", plural_name: "Limetten") }
  let!(:ingredient_mint) { create(:ingredient, name: "Minze") }

  let!(:recipe_ingredient_rum) do
    create(:recipe_ingredient,
      recipe: recipe,
      ingredient: ingredient_rum,
      amount: 4.0,
      unit: unit_cl,
      position: 1,
      is_garnish: false
    )
  end

  let!(:recipe_ingredient_lime) do
    create(:recipe_ingredient,
      recipe: recipe,
      ingredient: ingredient_lime,
      amount: 1.0,
      unit: unit_blank,
      position: 2,
      is_garnish: false
    )
  end

  let!(:recipe_ingredient_mint_garnish) do
    create(:recipe_ingredient,
      recipe: recipe,
      ingredient: ingredient_mint,
      amount: 1.0,
      unit: unit_piece,
      position: 3,
      is_garnish: true
    )
  end

  describe "GET /rezepte/:recipe_slug/zutaten" do
    context "without scale parameter" do
      it "returns ingredients with default scale of 1" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug), headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json).to have_key("ingredients")
        expect(json).to have_key("alcohol_info")
        expect(json["ingredients"]).to be_an(Array)
        expect(json["ingredients"].length).to eq(3)

        rum = json["ingredients"].find { |i| i["ingredient_name"] == "Rum (weiss)" }
        expect(rum["amount"]).to eq("4.0")
        expect(rum["unit_name"]).to eq("cl")
        expect(rum["formatted_amount"]).to eq("4 cl")
        expect(rum["is_garnish"]).to be false
      end

      it "returns correct ingredient structure" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug), headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        ingredient = json["ingredients"].first

        expect(ingredient).to have_key("id")
        expect(ingredient).to have_key("amount")
        expect(ingredient).to have_key("unit_name")
        expect(ingredient).to have_key("unit_display_name")
        expect(ingredient).to have_key("ingredient_name")
        expect(ingredient).to have_key("ingredient_plural_name")
        expect(ingredient).to have_key("formatted_amount")
        expect(ingredient).to have_key("additional_info")
        expect(ingredient).to have_key("is_garnish")
      end

      it "returns alcohol_info with total volume and alcohol content" do
        # Set alcohol content for rum
        ingredient_rum.update(alcoholic_content: 40.0)

        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug), headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        alcohol_info = json["alcohol_info"]

        expect(alcohol_info).to have_key("total_volume_ml")
        expect(alcohol_info).to have_key("alcohol_volume_ml")
        expect(alcohol_info).to have_key("alcohol_content_percent")
        expect(alcohol_info["total_volume_ml"].to_f).to eq(40.0) # 4cl rum = 40ml
      end
    end

    context "with scale=2" do
      it "doubles the ingredient amounts" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 2 },
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        rum = json["ingredients"].find { |i| i["ingredient_name"] == "Rum (weiss)" }
        expect(rum["amount"]).to eq("8.0")
        expect(rum["formatted_amount"]).to eq("8 cl")

        lime = json["ingredients"].find { |i| i["ingredient_plural_name"] == "Limetten" }
        expect(lime["amount"]).to eq("2.0")
      end

      it "does not scale garnishes" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 2 },
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        mint = json["ingredients"].find { |i| i["ingredient_name"] == "Minze" }

        expect(mint["amount"]).to eq("1.0")
        expect(mint["is_garnish"]).to be true
      end

      it "uses plural ingredient names when amount > 1 with blank unit" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 2 },
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        lime = json["ingredients"].find { |i| i["ingredient_plural_name"] == "Limetten" }

        expect(lime["amount"]).to eq("2.0")
        expect(lime["ingredient_name"]).to eq("Limetten")
        expect(lime["formatted_amount"]).to eq("2")
      end

      it "scales total volume but not alcohol percentage" do
        ingredient_rum.update(alcoholic_content: 40.0)

        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 2 },
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        alcohol_info = json["alcohol_info"]

        # Volume doubles: 4cl * 2 = 8cl = 80ml
        expect(alcohol_info["total_volume_ml"].to_f).to eq(80.0)
        # Alcohol volume also doubles: 40ml * 0.4 * 2 = 32ml
        expect(alcohol_info["alcohol_volume_ml"].to_f).to eq(32.0)
        # But percentage stays the same
        expect(alcohol_info["alcohol_content_percent"].to_f).to eq(40.0)
      end
    end

    context "with scale=0.5" do
      it "halves the ingredient amounts" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 0.5 },
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        rum = json["ingredients"].find { |i| i["ingredient_name"] == "Rum (weiss)" }
        expect(rum["amount"]).to eq("2.0")
        expect(rum["formatted_amount"]).to eq("2 cl")

        lime = json["ingredients"].find { |i| i["ingredient_name"] == "Limette" }
        expect(lime["amount"]).to eq("0.5")
      end
    end

    context "with scale=1.5" do
      it "scales ingredients by 1.5x" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 1.5 },
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        rum = json["ingredients"].find { |i| i["ingredient_name"] == "Rum (weiss)" }
        expect(rum["amount"]).to eq("6.0")
      end
    end

    context "with invalid recipe slug" do
      it "returns 404 not found" do
        get recipe_recipe_ingredients_path(recipe_slug: 'non-existent-recipe'),
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "allows unauthenticated access" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end

    context "with additional_info" do
      let!(:recipe_ingredient_with_info) do
        create(:recipe_ingredient,
          recipe: recipe,
          ingredient: create(:ingredient, name: "Rum"),
          amount: 3.0,
          unit: unit_cl,
          position: 4,
          additional_info: "braun",
          is_garnish: false
        )
      end

      it "includes additional_info in response" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        rum_with_info = json["ingredients"].find { |i| i["additional_info"] == "braun" }

        expect(rum_with_info).to be_present
        expect(rum_with_info["additional_info"]).to eq("braun")
      end
    end

    context "with plural ingredient names" do
      it "returns plural_name when available" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        lime = json["ingredients"].find { |i| i["ingredient_name"] == "Limette" }

        expect(lime["ingredient_plural_name"]).to eq("Limetten")
      end
    end

    context "with decimal amounts" do
      let!(:recipe_ingredient_decimal) do
        create(:recipe_ingredient,
          recipe: recipe,
          ingredient: create(:ingredient, name: "Tequila"),
          amount: 3.5,
          unit: unit_cl,
          position: 5,
          is_garnish: false
        )
      end

      it "formats decimal amounts with German format (comma)" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        tequila = json["ingredients"].find { |i| i["ingredient_name"] == "Tequila" }

        expect(tequila["amount"]).to eq("3.5")
        expect(tequila["formatted_amount"]).to eq("3,5 cl")
      end

      it "formats scaled decimal amounts with German format" do
        get recipe_recipe_ingredients_path(recipe_slug: recipe.slug),
            params: { scale: 0.5 },
            headers: { "Accept" => "application/json" }

        json = JSON.parse(response.body)
        tequila = json["ingredients"].find { |i| i["ingredient_name"] == "Tequila" }

        expect(tequila["amount"]).to eq("1.75")
        expect(tequila["formatted_amount"]).to eq("1,75 cl")
      end
    end
  end
end
