FactoryBot.define do
  factory :private_message do
    association :sender, factory: :user
    association :receiver, factory: :user
    subject { "Test Message" }
    body { "This is a test message body." }
    read { false }
    deleted_by_sender { false }
    deleted_by_receiver { false }

    trait :read do
      read { true }
    end

    trait :deleted_by_sender do
      deleted_by_sender { true }
    end

    trait :deleted_by_receiver do
      deleted_by_receiver { true }
    end

    trait :deleted_by_both do
      deleted_by_sender { true }
      deleted_by_receiver { true }
    end
  end
end
