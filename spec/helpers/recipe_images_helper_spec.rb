require 'rails_helper'

RSpec.describe RecipeImagesHelper, type: :helper do
  describe "#recipe_image_url" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user) }

    context "when image is attached" do
      it "returns the variant for the specified style" do
        recipe_image = RecipeImage.new(recipe: recipe, user: user)
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        recipe_image.image.attach(file)
        recipe_image.save!

        result = helper.recipe_image_url(recipe_image, style: :medium)

        expect(result).to be_present
        expect(result).to be_a(ActiveStorage::VariantWithRecord)
      end

      it "uses medium style by default" do
        recipe_image = RecipeImage.new(recipe: recipe, user: user)
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        recipe_image.image.attach(file)
        recipe_image.save!

        result = helper.recipe_image_url(recipe_image)

        expect(result).to be_present
        expect(result).to be_a(ActiveStorage::VariantWithRecord)
      end

      it "accepts different style options" do
        recipe_image = RecipeImage.new(recipe: recipe, user: user)
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        recipe_image.image.attach(file)
        recipe_image.save!

        [:thumb, :medium, :large].each do |style|
          result = helper.recipe_image_url(recipe_image, style: style)
          expect(result).to be_present
        end
      end
    end

    context "when image is not attached" do
      it "returns nil" do
        recipe_image = RecipeImage.new(recipe: recipe, user: user)

        result = helper.recipe_image_url(recipe_image)

        expect(result).to be_nil
      end

      it "returns nil regardless of style parameter" do
        recipe_image = RecipeImage.new(recipe: recipe, user: user)

        result = helper.recipe_image_url(recipe_image, style: :large)

        expect(result).to be_nil
      end
    end
  end
end
