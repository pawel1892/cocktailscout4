FactoryGirl.define do
  sequence(:ingredient_name) {|n| "Jägermeister#{n}"}
  factory :ingredient do |i|
    i.name { generate(:ingredient_name) }
    i.description 'Beschreibung'
    i.alcoholic_content Random.new.rand(73)
  end
end
