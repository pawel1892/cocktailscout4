FactoryBot.define do
  factory :wiki_article do
    sequence(:title) { |n| "Wiki Article #{n}" }
    sequence(:slug)  { |n| "wiki-article-#{n}" }
    body { "This is the body of the wiki article." }
    published { true }
    featured { false }
    association :user

    trait :unpublished do
      published { false }
    end

    trait :featured do
      featured { true }
      featured_position { 1 }
    end
  end
end
