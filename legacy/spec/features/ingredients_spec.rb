# TODO - find more elegant, generalized solution for copy-pasta in different roles testing

require 'rails_helper'

describe 'Recipes' do

  describe 'without login' do
    let! (:ingredient) { create :ingredient }

    it 'index returns to login' do
      visit ingredients_path
      expect(current_path).to eq new_user_session_path
    end
    it 'new returns to login' do
      visit new_ingredient_path
      expect(current_path).to eq new_user_session_path
    end
    it 'create returns to login' do
      page.driver.submit(:post, ingredients_path, ingredient: {value: '123'})
      expect(current_path).to eq new_user_session_path
    end
    it 'edit returns to login' do
      visit edit_ingredient_path(ingredient)
      expect(current_path).to eq new_user_session_path
    end
    it 'update returns to login' do
      page.driver.submit(:patch, ingredient_path(ingredient), {})
      expect(current_path).to eq new_user_session_path
    end
    it 'delete returns to login' do
      page.driver.submit(:delete, ingredient_path(ingredient), {})
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'with member login' do
    let! (:ingredient) { create :ingredient }
    include_context 'login as member'

    it 'index returns to login' do
      visit ingredients_path
      expect(current_path).to eq root_path
    end
    it 'new returns to login' do
      visit new_ingredient_path
      expect(current_path).to eq root_path
    end
    it 'create returns to login' do
      page.driver.submit(:post, ingredients_path, ingredient: {value: '123'})
      expect(current_path).to eq root_path
    end
    it 'edit returns to login' do
      visit edit_ingredient_path(ingredient)
      expect(current_path).to eq root_path
    end
    it 'update returns to login' do
      page.driver.submit(:patch, ingredient_path(ingredient), {})
      expect(current_path).to eq root_path
    end
    it 'delete returns to login' do
      page.driver.submit(:delete, ingredient_path(ingredient), {})
      expect(current_path).to eq root_path
    end
  end

  describe 'with login' do
    let! (:ingredients) { create_list :ingredient, 5 }
    include_context 'login as recipe_moderator'

    describe 'index' do
      it 'lists ingredients' do
        visit ingredients_path
        expect(page).to have_content ingredients.second.name
        expect(page).to have_content ingredients.first.alcoholic_content
        expect(page).to have_link 'bearbeiten'
        expect(page).to have_link 'löschen'
      end
    end

    describe 'create' do
      it 'creates an ingredient' do
        visit ingredients_path
        first(:link, 'neue Zutat erstellen').click
        fill_in :ingredient_name, with: 'Mampe Halb und Halb'
        fill_in :ingredient_alcoholic_content, with: '32.5'
        click_button 'speichern'
        expect(current_path).to eq ingredients_path
        expect(page).to have_content 'Mampe Halb und Halb'
        expect(page).to have_content '32.5'
      end
    end

    describe 'edit' do
      it 'edits an ingredient' do
        visit edit_ingredient_path(ingredients.second)
        expect(page).to have_selector("input[value=#{ingredients.second.name}]")
        fill_in :ingredient_name, with: 'Mampe Halb und Halb'
        fill_in :ingredient_alcoholic_content, with: '32.5'
        click_button 'speichern'
        expect(current_path).to eq ingredients_path
        expect(page).to have_content 'Mampe Halb und Halb'
        expect(page).to have_content '32.5'
      end
    end

    describe 'delete' do

      context 'ingredient without recipe' do
        it 'deletes an ingredient' do
          visit ingredients_path
          expect do
            first(:link, 'löschen').click
          end.to change { Ingredient.count }.by(-1)
        end
      end

      context 'ingredient with recipe' do
        let!(:recipe) { create :recipe }
        it 'does not delete ingredient' do
          expect do
            page.driver.submit(:delete, ingredient_path(recipe.ingredients.first), {})
          end.to_not change { Ingredient.count }
          expect(page).to have_content 'Zutat konnte nicht gelöscht werden, da sie noch in mindestens einem Rezept verwendet wird.'
        end
      end

    end

  end
end