FactoryBot.define do
  factory :forum_image do
    association :user

    trait :with_image do
      after(:build) do |forum_image|
        file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'),
          'image/jpeg'
        )
        forum_image.image.attach(file)
      end
    end

    trait :orphaned do
      orphaned_at { 1.day.ago }
    end

    trait :pending_deletion do
      orphaned_at { 31.days.ago }
    end
  end
end
