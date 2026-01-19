FactoryBot.define do
  factory :favorite do
    user
    favoritable { association :recipe }
    old_id { 1 }
  end
end
