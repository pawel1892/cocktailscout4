FactoryBot.define do
  factory :visit do
    visitable { nil }
    user { nil }
    count { 1 }
    last_visited_at { "2026-01-11 11:08:29" }
    old_id { 1 }
  end
end
