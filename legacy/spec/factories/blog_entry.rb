FactoryGirl.define do
  factory :blog_entry do
    title { Faker::Lorem.words(rand(2..10)).to_s }
    teaser { Faker::Lorem.paragraphs(rand(1..2)).to_s }
    content { Faker::Lorem.paragraphs(rand(2..4)).to_s }
    association :user
  end
end