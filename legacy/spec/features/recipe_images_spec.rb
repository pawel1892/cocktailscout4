require 'rails_helper'

describe 'RecipeImages' do

  let! (:recipe) { create :recipe }

  context 'with login' do
    include_context 'login as member'
    it "uploads recipe image" do
      visit new_recipe_recipe_image_path(recipe)
      attach_file "recipe_image_image", Rails.root.to_s + '/spec/fixtures/pic1.jpg', visible: false
      click_button 'Bild hochladen'

      expect(current_path).to eq recipe_path(recipe)
      # expect(page).to have_xpath("//img[@alt=\"#{recipe.name}\"]")
    end
  end


  context 'without login' do
    it 'expects login' do
      visit new_recipe_recipe_image_path(recipe)
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'cocktailgallery' do
    let! (:recipe) {create :recipe, name: 'not_approved_recipe'}
    let! (:not_approved_recipe_image) {create :recipe_image, is_approved: nil, approved_by: nil, recipe: recipe}
    let! (:approved_recipe_image) {create :recipe_image, is_approved: true, recipe: create(:recipe, name: 'approved_recipe')}

    context 'with image_moderator login' do
      include_context 'login as image_moderator'
      it "shows not approved images" do
        visit recipe_images_path(to_approve: true)
        expect(page).to have_content('not_approved_recipe')
      end
    end

    context 'with_member login' do
      include_context 'login as member'
      it "denies access to not approved images" do
        visit recipe_images_path(to_approve: true)
        expect(page).to_not have_content('not_approved_recipe')
      end
      it "shows approved images" do
        visit recipe_images_path
        expect(page).to have_content('approved_recipe')
      end
    end

    context 'approves image' do
      include_context 'login as image_moderator'
      it "approves an image" do
        visit recipe_images_path(to_approve: true)
        click_link 'freischalten'
        # expect(current_path).to eq(recipe_images_path(not_approved: true)) #FIXME #TODO
        expect(page).to have_content('Das Bild wurde freigeschaltet.')
        expect(not_approved_recipe_image.reload.is_approved).to eq(true)
      end
    end

  end

end