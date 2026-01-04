# app/models/legacy/user_profile.rb
module Legacy
  class UserProfile < LegacyRecord
    self.table_name = "user_profiles"
    belongs_to :user
  end
end
