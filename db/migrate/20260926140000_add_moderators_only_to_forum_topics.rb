class AddModeratorsOnlyToForumTopics < ActiveRecord::Migration[8.1]
  class MigrationForumTopic < ApplicationRecord
    self.table_name = "forum_topics"
  end

  def up
    add_column :forum_topics, :moderators_only, :boolean, default: false, null: false

    MigrationForumTopic.reset_column_information
    MigrationForumTopic.find_or_create_by!(slug: "moderatorentalk") do |topic|
      topic.name = "Moderatorentalk"
      topic.description = "Interner Austausch des Moderationsteams – nur für Admins und Moderatoren sichtbar"
      topic.position = -100
      topic.moderators_only = true
    end
  end

  def down
    MigrationForumTopic.where(slug: "moderatorentalk").delete_all
    remove_column :forum_topics, :moderators_only
  end
end
