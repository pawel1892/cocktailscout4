# app/models/legacy_record.rb
class LegacyRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :legacy
end
