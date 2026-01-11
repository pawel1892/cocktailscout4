FactoryBot.define do
  factory :forum_post do
    association :forum_thread
    association :user
    body { "MyText" }
    old_id { 1 }
  end
end
