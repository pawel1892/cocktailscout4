require 'rails_helper'

RSpec.describe User, type: :model do
  describe "Associations" do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:recipes).dependent(:nullify) }
    it { should have_many(:recipe_comments).dependent(:nullify) }
    it { should have_many(:forum_threads).dependent(:nullify) }
    it { should have_many(:forum_posts).dependent(:nullify) }
    it { should have_many(:recipe_images).dependent(:nullify) }
    it { should have_many(:ratings).dependent(:destroy) }
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:roles).through(:user_roles) }
    it { should have_one(:user_stat).dependent(:destroy) }
  end

  describe "Role methods" do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }
    let(:forum_mod) { create(:user, :forum_moderator) }
    let(:recipe_mod) { create(:user, :recipe_moderator) }
    let(:image_mod) { create(:user, :image_moderator) }

    describe "#admin?" do
      it "returns true for admin user" do
        expect(admin.admin?).to be true
      end

      it "returns false for regular user" do
        expect(user.admin?).to be false
      end

      it "returns false for other moderators" do
        expect(forum_mod.admin?).to be false
      end
    end

    describe "#forum_moderator?" do
      it "returns true for forum moderator" do
        expect(forum_mod.forum_moderator?).to be true
      end

      it "returns false for regular user" do
        expect(user.forum_moderator?).to be false
      end
    end

    describe "#recipe_moderator?" do
      it "returns true for recipe moderator" do
        expect(recipe_mod.recipe_moderator?).to be true
      end

      it "returns false for regular user" do
        expect(user.recipe_moderator?).to be false
      end
    end

    describe "#image_moderator?" do
      it "returns true for image moderator" do
        expect(image_mod.image_moderator?).to be true
      end

      it "returns false for regular user" do
        expect(user.image_moderator?).to be false
      end
    end

    describe "Multiple roles" do
      it "can have multiple roles" do
        super_mod = create(:user)
        super_mod.roles << create(:role, :admin)
        super_mod.roles << create(:role, :image_moderator)

        expect(super_mod.admin?).to be true
        expect(super_mod.image_moderator?).to be true
        expect(super_mod.recipe_moderator?).to be false
      end
    end
  end
end
