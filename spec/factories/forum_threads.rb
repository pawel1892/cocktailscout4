FactoryBot.define do
  factory :forum_thread do
    association :forum_topic
    association :user
    title { "MyString" }
    slug { "MyString" }
    sticky { false }
    locked { false }
    old_id { 1 }
  end
end
