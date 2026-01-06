class Legacy::Tagging < LegacyRecord
  self.table_name = "taggings"
  belongs_to :tag, class_name: "Legacy::Tag", foreign_key: "tag_id"
end
