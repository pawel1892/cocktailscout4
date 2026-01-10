FactoryBot.define do
  factory :rating do
    association :user
    association :rateable, factory: :recipe
    score { 5 }
    old_id { nil }
  end
end
