FactoryGirl.define do
  factory :recipe_rating_cache, class: RatingCache do
    cacheable_type 'Recipe'
    avg 8
    qty 3
    dimension 'taste'
  end
end