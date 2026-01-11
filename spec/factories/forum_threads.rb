FactoryBot.define do
  factory :forum_thread do
    forum_topic { nil }
    user { nil }
    title { "MyString" }
    slug { "MyString" }
    sticky { false }
    locked { false }
    old_id { 1 }
  end
end
