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
    it { should have_many(:ingredient_collections).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:sent_private_messages).class_name('PrivateMessage').with_foreign_key('sender_id').dependent(:destroy) }
    it { should have_many(:received_private_messages).class_name('PrivateMessage').with_foreign_key('receiver_id').dependent(:destroy) }
  end

  describe "Role methods" do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }
    let(:forum_mod) { create(:user, :forum_moderator) }
    let(:recipe_mod) { create(:user, :recipe_moderator) }
    let(:image_mod) { create(:user, :image_moderator) }
    let(:super_mod) { create(:user, :super_moderator) }

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

    describe "#super_moderator?" do
      it "returns true for super moderator" do
        expect(super_mod.super_moderator?).to be true
      end

      it "returns false for regular user" do
        expect(user.super_moderator?).to be false
      end
    end

    describe "#moderator?" do
      it "returns true for admin" do
        expect(admin.moderator?).to be true
      end

      it "returns true for forum moderator" do
        expect(forum_mod.moderator?).to be true
      end

      it "returns true for recipe moderator" do
        expect(recipe_mod.moderator?).to be true
      end

      it "returns true for image moderator" do
        expect(image_mod.moderator?).to be true
      end

      it "returns true for super moderator" do
        expect(super_mod.moderator?).to be true
      end

      it "returns false for regular user" do
        expect(user.moderator?).to be false
      end
    end

    describe "#can_moderate_forum?" do
      it "returns true for admin" do
        expect(admin.can_moderate_forum?).to be true
      end

      it "returns true for forum moderator" do
        expect(forum_mod.can_moderate_forum?).to be true
      end

      it "returns true for super moderator" do
        expect(super_mod.can_moderate_forum?).to be true
      end

      it "returns false for recipe moderator" do
        expect(recipe_mod.can_moderate_forum?).to be false
      end

      it "returns false for image moderator" do
        expect(image_mod.can_moderate_forum?).to be false
      end

      it "returns false for regular user" do
        expect(user.can_moderate_forum?).to be false
      end
    end

    describe "#can_moderate_recipe?" do
      it "returns true for admin" do
        expect(admin.can_moderate_recipe?).to be true
      end

      it "returns true for recipe moderator" do
        expect(recipe_mod.can_moderate_recipe?).to be true
      end

      it "returns true for super moderator" do
        expect(super_mod.can_moderate_recipe?).to be true
      end

      it "returns false for forum moderator" do
        expect(forum_mod.can_moderate_recipe?).to be false
      end

      it "returns false for image moderator" do
        expect(image_mod.can_moderate_recipe?).to be false
      end

      it "returns false for regular user" do
        expect(user.can_moderate_recipe?).to be false
      end
    end

    describe "#can_moderate_image?" do
      it "returns true for admin" do
        expect(admin.can_moderate_image?).to be true
      end

      it "returns true for image moderator" do
        expect(image_mod.can_moderate_image?).to be true
      end

      it "returns true for super moderator" do
        expect(super_mod.can_moderate_image?).to be true
      end

      it "returns false for forum moderator" do
        expect(forum_mod.can_moderate_image?).to be false
      end

      it "returns false for recipe moderator" do
        expect(recipe_mod.can_moderate_image?).to be false
      end

      it "returns false for regular user" do
        expect(user.can_moderate_image?).to be false
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

  describe "#default_collection" do
    let(:user) { create(:user) }

    context "when user has no collections" do
      it "returns nil" do
        expect(user.default_collection).to be_nil
      end
    end

    context "when user has one collection" do
      it "returns that collection" do
        collection = create(:ingredient_collection, user: user)
        expect(user.default_collection).to eq(collection)
      end
    end

    context "when user has multiple collections" do
      it "returns the default collection" do
        first = create(:ingredient_collection, user: user)
        first.update_column(:is_default, false)

        default_collection = create(:ingredient_collection, user: user, is_default: true)

        another = create(:ingredient_collection, user: user)
        another.update_column(:is_default, false)

        expect(user.default_collection).to eq(default_collection)
      end

      it "returns first collection if none are marked as default" do
        first = create(:ingredient_collection, user: user)
        first.update_column(:is_default, false)

        second = create(:ingredient_collection, user: user)
        second.update_column(:is_default, false)

        expect(user.default_collection).to eq(first)
      end
    end
  end

  describe ".online scope" do
    it "includes users active within 5 minutes" do
      user = create(:user, last_active_at: 4.minutes.ago)
      expect(User.online).to include(user)
    end

    it "excludes users active more than 5 minutes ago" do
      user = create(:user, last_active_at: 6.minutes.ago)
      expect(User.online).not_to include(user)
    end

    it "excludes users with no last_active_at" do
      user = create(:user, last_active_at: nil)
      expect(User.online).not_to include(user)
    end
  end

  describe "#online?" do
    it "returns true when active within 5 minutes" do
      user = create(:user, last_active_at: 4.minutes.ago)
      expect(user.online?).to be true
    end

    it "returns false when active more than 5 minutes ago" do
      user = create(:user, last_active_at: 6.minutes.ago)
      expect(user.online?).to be false
    end

    it "returns false when last_active_at is nil" do
      user = create(:user, last_active_at: nil)
      expect(user.online?).to be false
    end
  end

  describe "#unread_messages_count" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it "returns 0 when user has no messages" do
      expect(user.unread_messages_count).to eq(0)
    end

    it "returns count of unread received messages" do
      create(:private_message, sender: other_user, receiver: user, read: false)
      create(:private_message, sender: other_user, receiver: user, read: false)
      create(:private_message, sender: other_user, receiver: user, read: true)

      expect(user.unread_messages_count).to eq(2)
    end

    it "excludes messages deleted by receiver" do
      create(:private_message, sender: other_user, receiver: user, read: false)
      create(:private_message, :deleted_by_receiver, sender: other_user, receiver: user, read: false)

      expect(user.unread_messages_count).to eq(1)
    end

    it "does not count sent messages" do
      create(:private_message, sender: user, receiver: other_user, read: false)

      expect(user.unread_messages_count).to eq(0)
    end
  end
end
