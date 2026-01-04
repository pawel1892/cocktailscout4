# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  to_create do |instance|
    if !instance.save
      raise "Save failed for #{instance.class}"
    end
  end

  factory :forum_post do
    forum_thread
    user { FactoryGirl.build :user }
    ip "127.0.0.1"
    content "Wer das liest ist doof"
    deleted false
    last_editor_id nil
  end
end
