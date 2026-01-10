FactoryBot.define do
  factory :recipe_image do
    association :recipe
    association :user
    approved_by { nil }
    approved_at { nil }
    old_id { nil }

    trait :with_image do
      after(:build) do |recipe_image|
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'),
          'image/jpeg'
        )
        recipe_image.image.attach(file)
      end
    end

    trait :approved do
      approved_at { Time.current }
      association :approved_by, factory: :user
    end

    trait :pending do
      approved_at { nil }
      approved_by { nil }
    end
  end
end
