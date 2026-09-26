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
    let(:wiki_editor) { create(:user, :wiki_editor) }
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

    describe "#wiki_editor?" do
      it "returns true for wiki editor" do
        expect(wiki_editor.wiki_editor?).to be true
      end

      it "returns false for regular user" do
        expect(user.wiki_editor?).to be false
      end
    end

    describe "#can_edit_wiki?" do
      it "returns true for wiki editor" do
        expect(wiki_editor.can_edit_wiki?).to be true
      end

      it "returns false for admin" do
        expect(admin.can_edit_wiki?).to be false
      end

      it "returns false for super moderator" do
        expect(super_mod.can_edit_wiki?).to be false
      end

      it "returns false for regular user" do
        expect(user.can_edit_wiki?).to be false
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

  describe "Banning" do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }

    describe "#banned?" do
      it "is false without a ban" do
        expect(user.banned?).to be false
      end

      it "is true for a permanent ban" do
        user.update!(banned_at: 1.day.ago)
        expect(user.banned?).to be true
      end

      it "is true for a temporary ban that has not expired" do
        user.update!(banned_at: 1.day.ago, banned_until: 1.day.from_now)
        expect(user.banned?).to be true
      end

      it "is false for an expired temporary ban" do
        user.update!(banned_at: 2.days.ago, banned_until: 1.day.ago)
        expect(user.banned?).to be false
      end
    end

    describe ".banned" do
      it "returns only currently banned users" do
        permanent = create(:user, banned_at: 1.day.ago)
        temporary = create(:user, banned_at: 1.day.ago, banned_until: 1.day.from_now)
        create(:user, banned_at: 2.days.ago, banned_until: 1.day.ago)
        create(:user)

        expect(User.banned).to contain_exactly(permanent, temporary)
      end
    end

    describe "#ban!" do
      it "stores the ban details" do
        until_time = 3.days.from_now
        user.ban!(by: admin, reason: "Spam", until_time: until_time)

        expect(user.reload.banned_at).to be_present
        expect(user.banned_until).to be_within(1.second).of(until_time)
        expect(user.ban_reason).to eq("Spam")
        expect(user.banned_by).to eq(admin)
      end

      it "terminates all sessions" do
        user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")

        expect { user.ban!(by: admin, reason: "Spam") }.to change { user.sessions.count }.from(1).to(0)
      end
    end

    describe "#unban!" do
      it "clears all ban fields" do
        user.ban!(by: admin, reason: "Spam", until_time: 1.day.from_now)
        user.unban!

        expect(user.reload).to have_attributes(banned_at: nil, banned_until: nil, ban_reason: nil, banned_by: nil)
      end
    end

    describe "#can_ban_users?" do
      it "is true for admins and super moderators" do
        expect(admin.can_ban_users?).to be true
        expect(create(:user, :super_moderator).can_ban_users?).to be true
      end

      it "is false for other moderators and regular users" do
        expect(create(:user, :recipe_moderator).can_ban_users?).to be false
        expect(user.can_ban_users?).to be false
      end
    end
  end

  describe "Avatar" do
    let(:user) { create(:user) }
    let(:image_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.jpg"), "image/jpeg") }

    describe "attachment" do
      it "has one attached avatar" do
        expect(user).to respond_to(:avatar)
      end

      it "defines small variant" do
        user.avatar.attach(image_file)
        expect(user.avatar.variant(:small)).to be_present
      end

      it "defines medium variant" do
        user.avatar.attach(image_file)
        expect(user.avatar.variant(:medium)).to be_present
      end
    end

    describe "content type validation" do
      %w[image/jpeg image/png image/webp image/gif].each do |type|
        it "accepts #{type}" do
          user.avatar.attach(image_file)
          allow(user.avatar.blob).to receive(:content_type).and_return(type)
          expect(user).to be_valid
        end
      end

      it "rejects unsupported content types" do
        user.avatar.attach(image_file)
        allow(user.avatar.blob).to receive(:content_type).and_return("application/pdf")
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("muss ein JPEG, PNG, WebP oder GIF sein")
      end
    end

    describe "size validation" do
      it "accepts files within 5 MB" do
        user.avatar.attach(image_file)
        expect(user).to be_valid
      end

      it "rejects files larger than 5 MB" do
        user.avatar.attach(image_file)
        allow(user.avatar.blob).to receive(:byte_size).and_return(6.megabytes.to_i)
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("darf nicht größer als 5 MB sein")
      end
    end

    describe "#avatar_path" do
      it "returns nil when no avatar is attached" do
        expect(user.avatar_path).to be_nil
      end

      it "returns nil for medium size when no avatar is attached" do
        expect(user.avatar_path(:medium)).to be_nil
      end

      # rails_representation_path requires routing context (host/url_options) that isn't
      # available in model scope — stub it to test the method's own logic in isolation.
      it "returns the representation path when avatar is attached" do
        user.avatar.attach(image_file)
        allow(Rails.application.routes.url_helpers)
          .to receive(:rails_representation_path)
          .and_return("/rails/active_storage/representations/test")
        expect(user.avatar_path(:small)).to eq("/rails/active_storage/representations/test")
      end

      it "calls rails_representation_path with the correct variant" do
        user.avatar.attach(image_file)
        expect(Rails.application.routes.url_helpers)
          .to receive(:rails_representation_path)
          .with(an_instance_of(ActiveStorage::VariantWithRecord))
          .and_return("/mocked")
        user.avatar_path(:small)
      end

      it "returns nil when URL generation raises" do
        user.avatar.attach(image_file)
        allow(Rails.application.routes.url_helpers)
          .to receive(:rails_representation_path)
          .and_raise(StandardError)
        expect(user.avatar_path(:small)).to be_nil
      end
    end
  end
end
