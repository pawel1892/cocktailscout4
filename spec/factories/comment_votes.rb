FactoryBot.define do
  factory :comment_vote do
    association :user
    association :recipe_comment
    value { 1 }

    trait :downvote do
      value { -1 }
    end
  end
end
