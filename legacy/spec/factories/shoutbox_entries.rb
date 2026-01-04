FactoryGirl.define do
  factory :shoutbox_entry do
    association :user
    content 'Hallo Welt!'
  end
end
