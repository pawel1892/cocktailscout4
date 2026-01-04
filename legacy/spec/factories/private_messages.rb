FactoryGirl.define do
  factory :private_message do
    sender { FactoryGirl.build :user }
    receiver { FactoryGirl.build :user }
    subject 'Wer das liest ist doof'
    message 'echt jetzt'
  end
end
