require 'rails_helper'

describe Recipe do
  it "has a valid factory" do
    expect(FactoryGirl.create(:recipe)).to be_valid
  end

  describe "calculating cl_amount and alcoholic_content" do
    before :each do
      @recipe = FactoryGirl.create(:recipe)
    end

    it "can calculate cl_amount" do
      @recipe.refresh_cl_amount_and_alcoholic_content_cache
      expect(@recipe.cl_amount).to eq 2
    end

    it "can not calculate cl_amount when values are missing" do
      @recipe.recipe_ingredients.first.cl_amount = nil
      @recipe.refresh_cl_amount_and_alcoholic_content_cache
      expect(@recipe.cl_amount).to eq nil
    end

    it "can calculate alcoholic_content" do
      @recipe.refresh_cl_amount_and_alcoholic_content_cache
      expect(@recipe.alcoholic_content).to eq (@recipe.ingredients.map(&:alcoholic_content).sum)/2
    end

    it "can not calculate alcoholic_content when ingredient is missing" do
      @recipe.recipe_ingredients.first.ingredient_id = nil
      @recipe.refresh_cl_amount_and_alcoholic_content_cache
      expect(@recipe.alcoholic_content).to eq nil
    end

  end

  describe "scope name_like" do
    before :each do
      @hemingway = FactoryGirl.create(:recipe, :name => 'Hemingway')
      @hemingway_sour = FactoryGirl.create(:recipe, :name => 'Hemingway Sour')
    end
    it "finds Hemingway and Hemingway Sour with searchterm 'em'" do
      recipes = Recipe.name_like('em')
      expect(recipes).to include(@hemingway, @hemingway_sour)
    end
    it "finds Hemingway Sour with searchterm 'sour'" do
      recipes = Recipe.name_like('sour')
      expect(recipes).to include(@hemingway_sour)
    end
    it "does not find Hemingway with searchterm 'sour'" do
      recipes = Recipe.name_like('sour')
      expect(recipes).to_not include(@hemingway)
    end
  end

  describe "finding mixable coacktails from ingredients" do
    before :each do
      @ingredient1 = FactoryGirl.create(:ingredient)
      @ingredient2 = FactoryGirl.create(:ingredient)
      @ingredient3 = FactoryGirl.create(:ingredient)
      @ingredient4 = FactoryGirl.create(:ingredient)

      @recipe1 = FactoryGirl.create(:recipe, recipe_ingredients: [ create(:recipe_ingredient, ingredient: @ingredient2), create(:recipe_ingredient, ingredient: @ingredient3) ])
      @recipe2 = FactoryGirl.create(:recipe, recipe_ingredients: [ create(:recipe_ingredient, ingredient: @ingredient1), create(:recipe_ingredient, ingredient: @ingredient2), create(:recipe_ingredient, ingredient: @ingredient3) ])
      @recipe3 = FactoryGirl.create(:recipe)
    end

    it "finds mixable recipes" do
      result = Recipe::mixable_from_ingredients ([@ingredient1.id,@ingredient2.id,@ingredient3.id])
      expect(result).to include(@recipe1, @recipe2)

      result2 = Recipe::mixable_from_ingredients ([@ingredient2.id,@ingredient3.id,@ingredient4.id])
      expect(result2).to include(@recipe1)
    end

    it "does not find recipes with missing ingredients" do
      result = Recipe::mixable_from_ingredients ([@ingredient1.id,@ingredient2.id,@ingredient3.id])
      expect(result).to_not include(@recipe3)

      result2 = Recipe::mixable_from_ingredients ([@ingredient2.id,@ingredient3.id,@ingredient4.id])
      expect(result2).to_not include(@recipe2, @recipe3)
    end

  end

end
