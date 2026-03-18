class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :favoritable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :favoritable_type, :favoritable_id ], message: "has already favorited this item" }

  after_create_commit  -> { favoritable.increment!(:favorites_count) }
  after_destroy_commit -> { favoritable.decrement!(:favorites_count) }
end
