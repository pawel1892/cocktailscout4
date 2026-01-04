# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  to_create { |instance| instance.save }

  factory :forum_thread do
    forum_topic
    user { FactoryGirl.build :user }
    title "Bacardi oder Cola?"
    sticky false
    locked false
    deleted false
    slug "bacardi-oder-cola"
    before(:create) do |thread|
      thread.forum_posts << ForumPost.new(:user => (FactoryGirl.build(:user)), :content => 'Posting')
    end
  end
end
