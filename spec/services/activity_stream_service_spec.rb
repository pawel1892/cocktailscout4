require 'rails_helper'

RSpec.describe ActivityStreamService do
  subject(:result) { described_class.new(limit: 50).call }

  it 'returns an array' do
    expect(result).to be_an(Array)
  end

  it 'returns events sorted by created_at descending' do
    create(:recipe, created_at: 3.days.ago)
    create(:recipe, created_at: 1.hour.ago)
    timestamps = result.map { |e| e[:created_at] }
    expect(timestamps).to eq(timestamps.sort.reverse)
  end

  it 'respects the configured limit' do
    create_list(:recipe, 5)
    expect(described_class.new(limit: 2).call.size).to be <= 2
  end

  describe 'forum_post events' do
    let!(:thread) { create(:forum_thread) }
    let!(:post)   { create(:forum_post, forum_thread: thread) }

    it 'includes non-deleted posts' do
      expect(result).to include(hash_including(type: 'forum_post'))
    end

    it 'excludes deleted posts' do
      post.update_column(:deleted, true)
      urls = result.select { |e| e[:type] == 'forum_post' }.map { |e| e[:url] }
      expect(urls).not_to include("/cocktailforum/beitrag/#{post.public_id}")
    end

    it 'sets url to the direct post path' do
      event = result.find { |e| e[:type] == 'forum_post' }
      expect(event[:url]).to eq("/cocktailforum/beitrag/#{post.public_id}")
    end

    it 'includes thread_title and thread_url in meta' do
      event = result.find { |e| e[:type] == 'forum_post' }
      expect(event[:meta][:thread_title]).to eq(thread.title)
      expect(event[:meta][:thread_url]).to eq("/cocktailforum/thema/#{thread.slug}")
    end

    it 'includes excerpt in meta' do
      event = result.find { |e| e[:type] == 'forum_post' }
      expect(event[:meta][:excerpt]).to eq(post.body)
    end

    it 'truncates body longer than 120 characters' do
      post.update_column(:body, 'X' * 200)
      event = result.find { |e| e[:type] == 'forum_post' }
      expect(event[:meta][:excerpt]).to end_with('…')
      expect(event[:meta][:excerpt].length).to eq(121) # 120 chars + ellipsis
    end
  end

  describe 'rating events' do
    let!(:recipe) { create(:recipe) }
    let!(:rating) { create(:rating, rateable: recipe, score: 8) }

    it 'includes recipe ratings' do
      expect(result).to include(hash_including(type: 'rating'))
    end

    it 'sets score in meta' do
      event = result.find { |e| e[:type] == 'rating' }
      expect(event[:meta][:score]).to eq(8)
    end

    it 'sets recipe_title and recipe_url in meta' do
      event = result.find { |e| e[:type] == 'rating' }
      expect(event[:meta][:recipe_title]).to eq(recipe.title)
      expect(event[:meta][:recipe_url]).to eq("/rezepte/#{recipe.slug}")
    end

    it 'sets url to the recipe ratings page' do
      event = result.find { |e| e[:type] == 'rating' }
      expect(event[:url]).to eq("/rezepte/#{recipe.slug}/bewertungen")
    end

    it 'uses updated_at as the event timestamp' do
      rating.update_column(:updated_at, 2.hours.ago)
      event = result.find { |e| e[:type] == 'rating' }
      expect(event[:created_at]).to be_within(1.second).of(rating.updated_at)
    end

    it 'shows only the most recent rating per user' do
      user = create(:user)
      recipe2 = create(:recipe)
      old_rating = create(:rating, user: user, rateable: recipe, updated_at: 2.days.ago)
      new_rating = create(:rating, user: user, rateable: recipe2, updated_at: 1.hour.ago)

      rating_events = result.select { |e| e[:type] == 'rating' && e[:user][:id] == user.id }
      expect(rating_events.size).to eq(1)
      expect(rating_events.first[:meta][:recipe_title]).to eq(recipe2.title)
    end

    it 'shows different users most recent ratings independently' do
      user1 = create(:user)
      user2 = create(:user)
      recipe2 = create(:recipe)
      create(:rating, user: user1, rateable: recipe, updated_at: 1.hour.ago)
      create(:rating, user: user2, rateable: recipe2, updated_at: 2.hours.ago)

      user_ids = result.select { |e| e[:type] == 'rating' }.map { |e| e[:user][:id] }
      expect(user_ids).to include(user1.id, user2.id)
    end
  end

  describe 'recipe_image events' do
    let!(:recipe)         { create(:recipe) }
    let!(:approved_image) { create(:recipe_image, :approved, :with_image, recipe: recipe) }

    it 'includes approved non-soft-deleted images' do
      expect(result).to include(hash_including(type: 'recipe_image'))
    end

    it 'excludes pending images' do
      pending_image = create(:recipe_image, :with_image, recipe: recipe)
      event_ids = result.select { |e| e[:type] == 'recipe_image' }.map { |e| e.dig(:meta, :recipe_image_id) }
      expect(event_ids).not_to include(pending_image.id)
    end

    it 'excludes soft-deleted images' do
      approved_image.soft_delete!
      expect(result).not_to include(hash_including(type: 'recipe_image'))
    end

    it 'includes recipe_image_id in meta' do
      event = result.find { |e| e[:type] == 'recipe_image' }
      expect(event[:meta][:recipe_image_id]).to eq(approved_image.id)
    end

    it 'sets url to the recipe path' do
      event = result.find { |e| e[:type] == 'recipe_image' }
      expect(event[:url]).to eq("/rezepte/#{recipe.slug}")
    end

    it 'includes recipe_title in meta' do
      event = result.find { |e| e[:type] == 'recipe_image' }
      expect(event[:meta][:recipe_title]).to eq(recipe.title)
    end
  end

  describe 'recipe events' do
    let!(:recipe) { create(:recipe, is_public: true, is_deleted: false) }

    it 'includes public non-deleted recipes' do
      event = result.find { |e| e[:type] == 'recipe' && e[:url] == "/rezepte/#{recipe.slug}" }
      expect(event).to be_present
    end

    it 'excludes draft recipes' do
      draft = create(:recipe, :draft)
      urls = result.select { |e| e[:type] == 'recipe' }.map { |e| e[:url] }
      expect(urls).not_to include("/rezepte/#{draft.slug}")
    end

    it 'excludes deleted recipes' do
      deleted = create(:recipe, :deleted)
      urls = result.select { |e| e[:type] == 'recipe' }.map { |e| e[:url] }
      expect(urls).not_to include("/rezepte/#{deleted.slug}")
    end

    it 'includes recipe_title in meta' do
      event = result.find { |e| e[:type] == 'recipe' && e[:url] == "/rezepte/#{recipe.slug}" }
      expect(event[:meta][:recipe_title]).to eq(recipe.title)
    end
  end

  describe 'user_registration events' do
    let!(:confirmed_user) { create(:user, confirmed_at: 1.day.ago) }

    it 'includes confirmed users' do
      event = result.find { |e| e[:type] == 'user_registration' && e[:user][:id] == confirmed_user.id }
      expect(event).to be_present
    end

    it 'excludes unconfirmed users' do
      unconfirmed = create(:user, :unconfirmed)
      user_ids = result.select { |e| e[:type] == 'user_registration' }.map { |e| e[:user][:id] }
      expect(user_ids).not_to include(unconfirmed.id)
    end

    it 'uses confirmed_at as created_at' do
      event = result.find { |e| e[:type] == 'user_registration' && e[:user][:id] == confirmed_user.id }
      expect(event[:created_at]).to be_within(1.second).of(confirmed_user.confirmed_at)
    end

    it 'has a nil url' do
      event = result.find { |e| e[:type] == 'user_registration' && e[:user][:id] == confirmed_user.id }
      expect(event[:url]).to be_nil
    end

    it 'has an empty meta hash' do
      event = result.find { |e| e[:type] == 'user_registration' && e[:user][:id] == confirmed_user.id }
      expect(event[:meta]).to eq({})
    end
  end

  describe 'recipe_comment events' do
    let!(:recipe)  { create(:recipe) }
    let!(:comment) { create(:recipe_comment, recipe: recipe) }

    it 'includes recipe comments' do
      expect(result).to include(hash_including(type: 'recipe_comment'))
    end

    it 'sets url with #kommentare anchor' do
      event = result.find { |e| e[:type] == 'recipe_comment' }
      expect(event[:url]).to eq("/rezepte/#{recipe.slug}#kommentare")
    end

    it 'includes recipe_title and recipe_url in meta' do
      event = result.find { |e| e[:type] == 'recipe_comment' }
      expect(event[:meta][:recipe_title]).to eq(recipe.title)
      expect(event[:meta][:recipe_url]).to eq("/rezepte/#{recipe.slug}")
    end

    it 'includes excerpt in meta' do
      event = result.find { |e| e[:type] == 'recipe_comment' }
      expect(event[:meta][:excerpt]).to eq(comment.body)
    end

    it 'truncates body longer than 120 characters' do
      comment.update_column(:body, 'Y' * 200)
      event = result.find { |e| e[:type] == 'recipe_comment' }
      expect(event[:meta][:excerpt]).to end_with('…')
      expect(event[:meta][:excerpt].length).to eq(121)
    end
  end

  describe 'user serialization' do
    context 'when the user exists with a stat' do
      let!(:user)   { create(:user) }
      let!(:stat)   { create(:user_stat, user: user, points: 500) }
      let!(:recipe) { create(:recipe, user: user) }

      it 'includes id, username, and integer rank' do
        event = result.find { |e| e[:type] == 'recipe' && e[:user][:id] == user.id }
        expect(event[:user]).to include(id: user.id, username: user.username)
        expect(event[:user][:rank]).to be_a(Integer)
      end
    end

    context 'when the user has been deleted (nil association)' do
      let!(:post) { create(:forum_post) }

      before { post.update_column(:user_id, nil) }

      it 'returns the deleted-user placeholder' do
        event = result.find { |e| e[:type] == 'forum_post' && e[:url].include?(post.public_id) }
        expect(event[:user]).to eq(id: nil, username: 'Gelöschter Benutzer', rank: nil)
      end
    end

    context 'when the user has no user_stat' do
      let!(:user)   { create(:user) }
      let!(:recipe) { create(:recipe, user: user) }

      before { user.user_stat&.destroy }

      it 'returns rank 0' do
        event = result.find { |e| e[:type] == 'recipe' && e[:user][:id] == user.id }
        expect(event[:user][:rank]).to eq(0)
      end
    end
  end

  describe 'event shape' do
    let!(:recipe) { create(:recipe) }

    it 'every event has type, created_at, user, url, and meta keys' do
      result.each do |event|
        expect(event).to include(:type, :created_at, :user, :url, :meta)
      end
    end

    it 'user hash always has id, username, and rank keys' do
      result.each do |event|
        expect(event[:user]).to include(:id, :username, :rank)
      end
    end
  end
end
