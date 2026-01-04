# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :forum_topic do
    name "Allgemeine Diskussion"
    description "Hier wird geplaudert"
    slug "allgemeine-diskussion"
  end
end
