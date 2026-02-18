require 'rails_helper'

RSpec.describe RecipeImage, type: :model do
  describe "associations" do
    it { should belong_to(:recipe) }
    it { should belong_to(:user) }
    it { should belong_to(:approved_by).class_name('User').optional }
  end

  describe "validations" do
    it { should validate_presence_of(:image) }
  end

  describe "image content type validation" do
    let(:user)   { create(:user) }
    let(:recipe) { create(:recipe, user: user) }

    def build_with_type(content_type)
      ri   = RecipeImage.new(recipe: recipe, user: user)
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), content_type)
      ri.image.attach(file)
      ri
    end

    %w[image/jpeg image/png image/webp image/gif].each do |type|
      it "accepts #{type}" do
        expect(build_with_type(type)).to be_valid
      end
    end

    it "rejects unsupported content types" do
      ri = RecipeImage.new(recipe: recipe, user: user)
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")
      ri.image.attach(file)
      allow(ri.image.blob).to receive(:content_type).and_return("application/pdf")
      expect(ri).not_to be_valid
      expect(ri.errors[:image]).to include("muss ein JPEG, PNG, WebP oder GIF sein")
    end
  end

  describe "image size validation" do
    let(:user)   { create(:user) }
    let(:recipe) { create(:recipe, user: user) }

    it "accepts files within the 10 MB limit" do
      ri   = RecipeImage.new(recipe: recipe, user: user)
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")
      ri.image.attach(file)
      expect(ri).to be_valid
    end

    it "rejects files larger than 10 MB" do
      ri   = RecipeImage.new(recipe: recipe, user: user)
      file = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.jpg"), "image/jpeg")
      ri.image.attach(file)
      allow(ri.image.blob).to receive(:byte_size).and_return(11.megabytes.to_i)
      expect(ri).not_to be_valid
      expect(ri.errors[:image]).to include("darf nicht größer als 10 MB sein")
    end
  end

  describe "Active Storage" do
    it "has one attached image" do
      recipe_image = build(:recipe_image)
      expect(recipe_image).to respond_to(:image)
    end

    it "defines thumb variant" do
      user = create(:user)
      recipe = create(:recipe, user: user)
      recipe_image = RecipeImage.new(recipe: recipe, user: user)

      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image.image.attach(file)

      expect(recipe_image.image.variant(:thumb)).to be_present
    end

    it "defines medium variant" do
      user = create(:user)
      recipe = create(:recipe, user: user)
      recipe_image = RecipeImage.new(recipe: recipe, user: user)

      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image.image.attach(file)

      expect(recipe_image.image.variant(:medium)).to be_present
    end

    it "defines large variant" do
      user = create(:user)
      recipe = create(:recipe, user: user)
      recipe_image = RecipeImage.new(recipe: recipe, user: user)

      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image.image.attach(file)

      expect(recipe_image.image.variant(:large)).to be_present
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user) }
    let(:approver) { create(:user) }

    before do
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')

      @approved_image = RecipeImage.new(
        recipe: recipe,
        user: user,
        approved_at: Time.current,
        approved_by: approver
      )
      @approved_image.image.attach(file)
      @approved_image.save!

      @pending_image = RecipeImage.new(
        recipe: recipe,
        user: user,
        approved_at: nil
      )
      @pending_image.image.attach(file)
      @pending_image.save!
    end

    describe ".approved" do
      it "returns only approved images" do
        expect(RecipeImage.approved).to include(@approved_image)
        expect(RecipeImage.approved).not_to include(@pending_image)
      end

      it "returns images with approved_at set" do
        expect(RecipeImage.approved.all? { |img| img.approved_at.present? }).to be true
      end
    end

    describe ".pending" do
      it "returns only pending images" do
        expect(RecipeImage.pending).to include(@pending_image)
        expect(RecipeImage.pending).not_to include(@approved_image)
      end

      it "returns images with approved_at nil" do
        expect(RecipeImage.pending.all? { |img| img.approved_at.nil? }).to be true
      end
    end
  end

  describe "approval workflow" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user) }
    let(:approver) { create(:user) }

    it "can be created without approval" do
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image = RecipeImage.new(recipe: recipe, user: user)
      recipe_image.image.attach(file)
      recipe_image.save!

      expect(recipe_image.approved_at).to be_nil
      expect(recipe_image.approved_by).to be_nil
    end

    it "can be approved by setting approved_at and approved_by" do
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image = RecipeImage.new(recipe: recipe, user: user)
      recipe_image.image.attach(file)
      recipe_image.save!

      recipe_image.update!(approved_at: Time.current, approved_by: approver)

      expect(recipe_image.approved_at).to be_present
      expect(recipe_image.approved_by).to eq(approver)
    end
  end

  describe "when recipe is deleted" do
    it "is also deleted" do
      user = create(:user)
      recipe = create(:recipe, user: user)
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      recipe_image = RecipeImage.new(recipe: recipe, user: user)
      recipe_image.image.attach(file)
      recipe_image.save!

      expect { recipe.destroy }.to change { RecipeImage.count }.by(-1)
    end
  end
end
