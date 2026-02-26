require 'rails_helper'

RSpec.describe RecipeImage, type: :model do
  describe "associations" do
    it { should belong_to(:recipe) }
    it { should belong_to(:user) }
    it { should belong_to(:moderated_by).class_name('User').optional }
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
    let(:moderator) { create(:user) }

    before do
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')

      @approved_image = RecipeImage.new(recipe: recipe, user: user, state: "approved",
                                        moderated_at: Time.current, moderated_by: moderator)
      @approved_image.image.attach(file)
      @approved_image.save!

      @pending_image = RecipeImage.new(recipe: recipe, user: user, state: "pending")
      @pending_image.image.attach(file)
      @pending_image.save!

      @rejected_image = RecipeImage.new(recipe: recipe, user: user, state: "rejected",
                                        moderated_at: Time.current, moderated_by: moderator,
                                        moderation_reason: "Inappropriate content")
      @rejected_image.image.attach(file)
      @rejected_image.save!
    end

    describe ".by_user" do
      let(:user2) { create(:user) }
      let(:recipe2) { create(:recipe, user: user2) }

      before do
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        @image_user2 = RecipeImage.new(recipe: recipe2, user: user2, state: "approved",
                                       moderated_at: Time.current, moderated_by: moderator)
        @image_user2.image.attach(file)
        @image_user2.save!
      end

      it "returns only images by the given user" do
        expect(RecipeImage.by_user(user.id)).to include(@approved_image)
        expect(RecipeImage.by_user(user.id)).not_to include(@image_user2)
      end

      it "returns all images if user_id is nil" do
        expect(RecipeImage.by_user(nil)).to include(@approved_image, @image_user2)
      end

      it "returns all images if user_id is blank" do
        expect(RecipeImage.by_user("")).to include(@approved_image, @image_user2)
      end
    end

    describe ".by_recipe_name" do
      let(:recipe2) { create(:recipe, title: "Daiquiri", user: user) }

      before do
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        @daiquiri_image = RecipeImage.new(recipe: recipe2, user: user, state: "approved",
                                          moderated_at: Time.current, moderated_by: moderator)
        @daiquiri_image.image.attach(file)
        @daiquiri_image.save!
      end

      it "returns images whose recipe title matches the query" do
        expect(RecipeImage.by_recipe_name(recipe.title)).to include(@approved_image)
        expect(RecipeImage.by_recipe_name(recipe.title)).not_to include(@daiquiri_image)
      end

      it "matches partial recipe titles" do
        expect(RecipeImage.by_recipe_name("Daiq")).to include(@daiquiri_image)
        expect(RecipeImage.by_recipe_name("Daiq")).not_to include(@approved_image)
      end

      it "returns all images if query is nil" do
        expect(RecipeImage.by_recipe_name(nil)).to include(@approved_image, @daiquiri_image)
      end

      it "returns all images if query is blank" do
        expect(RecipeImage.by_recipe_name("")).to include(@approved_image, @daiquiri_image)
      end
    end

    describe ".approved" do
      it "returns only approved images" do
        expect(RecipeImage.approved).to include(@approved_image)
        expect(RecipeImage.approved).not_to include(@pending_image)
        expect(RecipeImage.approved).not_to include(@rejected_image)
      end
    end

    describe ".pending" do
      it "returns only pending images" do
        expect(RecipeImage.pending).to include(@pending_image)
        expect(RecipeImage.pending).not_to include(@approved_image)
        expect(RecipeImage.pending).not_to include(@rejected_image)
      end
    end

    describe ".rejected" do
      it "returns only rejected images" do
        expect(RecipeImage.rejected).to include(@rejected_image)
        expect(RecipeImage.rejected).not_to include(@approved_image)
        expect(RecipeImage.rejected).not_to include(@pending_image)
      end
    end
  end

  describe "moderation workflow" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user) }
    let(:moderator) { create(:user) }

    def build_recipe_image
      ri = RecipeImage.new(recipe: recipe, user: user)
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
      ri.image.attach(file)
      ri.save!
      ri
    end

    it "is created with pending state by default" do
      ri = build_recipe_image
      expect(ri.state).to eq("pending")
      expect(ri.pending?).to be true
      expect(ri.moderated_at).to be_nil
      expect(ri.moderated_by).to be_nil
    end

    describe "#approve!" do
      it "sets state to approved" do
        ri = build_recipe_image
        ri.approve!(moderator)
        expect(ri.reload.state).to eq("approved")
        expect(ri.approved?).to be true
      end

      it "records the moderator and timestamp" do
        ri = build_recipe_image
        ri.approve!(moderator)
        ri.reload
        expect(ri.moderated_by).to eq(moderator)
        expect(ri.moderated_at).to be_present
      end
    end

    describe "#reject!" do
      it "sets state to rejected" do
        ri = build_recipe_image
        ri.reject!(moderator, "Inappropriate content")
        expect(ri.reload.state).to eq("rejected")
        expect(ri.rejected?).to be true
      end

      it "records the moderator, timestamp, and reason" do
        ri = build_recipe_image
        ri.reject!(moderator, "Inappropriate content")
        ri.reload
        expect(ri.moderated_by).to eq(moderator)
        expect(ri.moderated_at).to be_present
        expect(ri.moderation_reason).to eq("Inappropriate content")
      end

      it "allows rejection without a reason" do
        ri = build_recipe_image
        ri.reject!(moderator, nil)
        expect(ri.reload.state).to eq("rejected")
        expect(ri.moderation_reason).to be_nil
      end
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
