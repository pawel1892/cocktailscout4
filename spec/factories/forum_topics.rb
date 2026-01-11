FactoryBot.define do
  factory :forum_topic do
    name { "MyString" }
    description { "MyText" }
    slug { "MyString" }
    position { 1 }
    old_id { 1 }
  end
end
