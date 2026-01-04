require 'rails_helper'

describe 'Recipes' do

  describe 'without login' do
    let!(:recipe) { create :recipe}

    it 'new returns to login' do
      visit new_recipe_path
      expect(current_path).to eq new_user_session_path
    end
    it 'create returns to login' do
      page.driver.submit(:post, recipes_path, recipe: {value: '123'})
      expect(current_path).to eq new_user_session_path
    end
    it 'edit returns to login' do
      visit edit_recipe_path(recipe)
      expect(current_path).to eq new_user_session_path
    end
    it 'update returns to login' do
      page.driver.submit(:patch, recipe_path(recipe), {})
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'with member login' do
    let!(:recipe) { create :recipe }
    include_context 'login as member'

    it 'edit returns to login' do
      visit edit_recipe_path(recipe)
      expect(current_path).to eq root_path
    end
    it 'update returns to login' do
      page.driver.submit(:patch, recipe_path(recipe), {})
      expect(current_path).to eq root_path
    end

    context 'own recipe' do
      let!(:own_recipe) { create :recipe, user: current_user }
      it 'allows edit' do
        visit edit_recipe_path(own_recipe)
        expect(page).to have_selector("input[value='#{own_recipe.name}']")
      end
    end
  end

  describe 'show' do
    let(:recipe) { create(:recipe, :name => 'Bacardi Cola', :description => 'muss nicht sein') }

    it "shows recipe" do
      visit recipe_path(recipe)
      expect(page).to have_content 'Bacardi Cola'
      expect(page).to have_content 'muss nicht sein'
    end

    context 'view counter' do
      it "increments visit counter" do
        visit recipe_path(recipe)
        expect(recipe.visits_count).to eq 1
        visit recipe_path(recipe)
        expect(recipe.visits_count).to eq 2
      end
    end
  end

  describe 'index' do

    context 'sorting by name' do
      let!(:recipe_with_a) { create :recipe, name: 'Aaaaa Recipe'}
      let!(:recipe_with_z) { create :recipe, name: 'Zzzzz Recipe'}
      it "sorts by name" do
        visit recipes_path
        click_link('Name')
        expect(recipe_with_a.name).to appear_before(recipe_with_z.name)
        click_link('Name')
        expect(recipe_with_z.name).to appear_before(recipe_with_a.name)
      end
    end

    context 'sorting by alcoholic_content' do
      let!(:strong_recipe) { create :recipe, name: 'strong'}
      let!(:weak_recipe) { create :recipe, :non_alcoholic, name: 'weak'}
      it "sorts by alcoholic_content" do
        weak_recipe.save #update alcoholic_content cache #todo make better factories
        visit recipes_path
        click_link('Alk.')
        expect(weak_recipe.name).to appear_before(strong_recipe.name)
        click_link('Alk.')
        expect(strong_recipe.name).to appear_before(weak_recipe.name)
      end
    end

    context 'sorting by rating' do
      let!(:bad_rated_recipe) { create :recipe, name: 'bad stuff'}
      let!(:recipe_rating_cache) { create :recipe_rating_cache, cacheable_id: bad_rated_recipe.id, avg: 2 }
      let!(:good_rated_recipe) { create :recipe, name: 'good stuff'}
      let!(:recipe_rating_cache) { create :recipe_rating_cache, cacheable_id: good_rated_recipe.id, avg: 5 }
      it "sorts by rating" do
        visit recipes_path
        click_link('Bewertung')
        expect(bad_rated_recipe.name).to appear_before(good_rated_recipe.name)
        click_link('Bewertung')
        expect(good_rated_recipe.name).to appear_before(bad_rated_recipe.name)
      end
    end

    context 'sorting by user_name' do
      let!(:user_bolek) { create :user, login: 'Bolek'}
      let!(:user_lolek) { create :user, login: 'Lolek'}
      let!(:boleks_recipe) { create :recipe, user: user_bolek, name: 'bolek'}
      let!(:loleks_recipe) { create :recipe, user: user_lolek, name: 'lolek'}
      it "sorts by user_name" do
        visit recipes_path
        click_link('User')
        expect(boleks_recipe.name).to appear_before(loleks_recipe.name)
        click_link('User')
        expect(loleks_recipe.name).to appear_before(boleks_recipe.name)
      end
    end

    context 'sorting by created_at' do
      let!(:old_recipe) {
        old_recipe = create :recipe, name: 'old_recipe'
        old_recipe.update_attribute(:created_at, Time.now - 1.day)
        old_recipe
      }
      let!(:new_recipe) { create :recipe, name: 'new_recipe'}
      it "sorts by created_at" do
        visit recipes_path
        click_link('Erstellt')
        expect(old_recipe.name).to appear_before(new_recipe.name)
        click_link('Erstellt')
        expect(new_recipe.name).to appear_before(old_recipe.name)
      end
    end

  end

  describe 'new' do
    let!(:ingredients) { create_list :ingredient, 3}
    context 'create a new recipe' do
      include_context 'login as member'
      pending 'creates a new recipe' do
        #TODO: needs javascript to run
        visit new_recipe_path
        fill_in :recipe_name, with: 'Kalle hat Durst'
        select Ingredient.first.name, from: :recipe_recipe_ingredients_attributes_0_ingredient_id
        fill_in :recipe_recipe_ingredients_attributes_0_cl_amount, with: '4'
        fill_in :recipe_recipe_ingredients_attributes_0_description, with: '4 cl Zufallszutat'
        select Ingredient.third.name, from: :recipe_recipe_ingredients_attributes_1_ingredient_id
        fill_in :recipe_recipe_ingredients_attributes_1_cl_amount, with: '2'
        fill_in :recipe_recipe_ingredients_attributes_1_description, with: '2 cl Zufallszutat'
        fill_in :recipe_description, with: 'Rezeptbeschreibung'
        expect { click_button 'speichern' }.to change { Recipe.count }.by(1)
        recipe = Recipe.last
        expect(current_path).to eq(recipe_path(recipe))
        expect(recipe.name).to eq 'Kalle hat Durst'
        expect(recipe.description).to eq 'Rezeptbeschreibung'
        expect(recipe.recipe_ingredients.count).to eq 2
        expect(recipe.recipe_ingredients.first.cl_amount).to eq 4
      end
    end
  end

  describe 'edit' do
    let!(:recipe) { create :recipe }
    context 'edits an existing recipe' do
      include_context 'login as recipe_moderator'
      it 'edits' do
        visit edit_recipe_path(recipe)
        expect(page).to have_selector("input[value='#{recipe.name}']")
        expect(page).to have_content(recipe.description)
        expect(page).to have_selector("input[value='#{recipe.recipe_ingredients.first.cl_amount}']")
        expect(page).to have_selector("input[value='#{recipe.recipe_ingredients.second.description}']")
        fill_in :recipe_name, with: 'Atze hat Durst'
        click_button 'speichern'
        expect(recipe.reload.name).to eq 'Atze hat Durst'
      end
    end
  end
  
  

end