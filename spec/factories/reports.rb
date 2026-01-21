FactoryBot.define do
  factory :report do
    association :reporter, factory: :user
    association :reportable, factory: :forum_post
    reason { "spam" }
    description { "This is spam" }
    status { "pending" }
  end
end
