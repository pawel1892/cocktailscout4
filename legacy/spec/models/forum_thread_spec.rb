require 'rails_helper'

describe ForumThread do
  it "has a valid factory" do
    expect(FactoryGirl.create(:forum_thread)).to be_valid
  end

  it "can count posts" do
    thread = FactoryGirl.create(:forum_thread)
    thread.forum_posts << ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
    thread.forum_posts << ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli2')
    thread.save
    expect(thread.reload.count_posts).to eq 3
  end

  describe ".ordered_posts" do
    it "orders posts by time of creation" do
      thread = FactoryGirl.create(:forum_thread)
      second_post = ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
      thread.forum_posts << second_post
      sleep 1
      third_post = ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli2')
      thread.forum_posts << third_post
      thread.save
      expect(thread.ordered_posts.third).to eq third_post
      expect(thread.ordered_posts.second).to eq second_post
    end

    it "does not contain deleted posts" do
      thread = FactoryGirl.create(:forum_thread)
      post = ForumPost.new(user: FactoryGirl.create(:user),content: 'post', deleted: true)
      thread.forum_posts << post
      thread.save
      expect(thread.reload.ordered_posts).not_to include post
    end
  end

  describe ".delete" do
    before :each do
      @thread = FactoryGirl.create(:forum_thread)
      @post = ForumPost.new(user: FactoryGirl.create(:user),content: 'post')
      @thread.forum_posts << @post
      @thread.save
    end

    it "should remove post from collection" do
      @post.delete
      expect(ForumPost.all).not_to include @post
    end

    it "should keep the post in an unscoped colletion" do
      @post.delete
      expect(ForumPost.unscoped.find(@post.id)).to eq @post
    end
  end

  describe ".read_by?" do
    before :each do
      @user_author = FactoryGirl.create(:user)
      @user_reader = FactoryGirl.create(:user)
      @thread = FactoryGirl.create(:forum_thread)
      @post = ForumPost.new(user: @user_author, content: 'post')
      @thread.forum_posts << @post
      @thread.save
    end

    it "returns false if user has not visited the thread" do
      expect(@thread.read_by?(@user_reader)).to eq false
    end

    it "returns true if user has visited thread after last post was written" do
      Visit.track(@thread, @user_reader)
      expect(@thread.read_by?(@user_reader)).to eq true
    end

  end

  it "caches the last post time" do
    thread = FactoryGirl.create(:forum_thread)
    post = ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
    thread.forum_posts << post
    thread.save
    expect(thread.reload.last_post_created_cache.to_i).to eq post.created_at.to_i
  end

  it "caches the last post user" do
    thread = FactoryGirl.create(:forum_thread)
    post = ForumPost.new(user: FactoryGirl.create(:user), content: 'Bli')
    thread.forum_posts << post
    thread.save
    expect(thread.reload.last_post_user_id_cache).to eq post.user_id
  end

end
