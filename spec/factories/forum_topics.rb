FactoryBot.define do
  factory :forum_topic do
    name { "MyString" }
    description { "MyText" }
    slug { "MyString" }
    position { 1 }
    old_id { 1 }

    trait :moderators_only do
      moderators_only { true }
    end
  end
end
