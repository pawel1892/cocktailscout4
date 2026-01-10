FactoryBot.define do
  factory :user_stat do
    association :user
    points { 0 }
  end
end
