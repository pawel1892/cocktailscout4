FactoryBot.define do
  factory :forum_post do
    forum_thread { nil }
    user { nil }
    body { "MyText" }
    old_id { 1 }
  end
end
