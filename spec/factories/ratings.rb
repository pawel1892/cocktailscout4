FactoryBot.define do
  factory :rating do
    user { nil }
    rateable { nil }
    score { 1 }
    old_id { 1 }
  end
end
