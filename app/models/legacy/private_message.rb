# app/models/legacy/private_message.rb
module Legacy
  class PrivateMessage < LegacyRecord
    self.table_name = "private_messages"
  end
end
