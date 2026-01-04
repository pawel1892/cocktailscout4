# app/models/legacy/user.rb
module Legacy
  class User < LegacyRecord
    self.table_name = "users"
    has_one :user_profile, foreign_key: :user_id
  end
end
