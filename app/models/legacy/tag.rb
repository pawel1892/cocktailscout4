class Legacy::Tag < LegacyRecord
  self.table_name = "tags"
  has_many :taggings, class_name: "Legacy::Tagging", foreign_key: "tag_id"
end
