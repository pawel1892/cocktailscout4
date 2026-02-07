class AddDisplayNameToRolesAndCreateSuperModerator < ActiveRecord::Migration[8.1]
  def change
    add_column :roles, :display_name, :string

    reversible do |dir|
      dir.up do
        Role.reset_column_information
        Role.find_by(name: 'admin')&.update(display_name: 'Admin')
        Role.find_by(name: 'forum_moderator')&.update(display_name: 'Forum-Moderator')
        Role.find_by(name: 'recipe_moderator')&.update(display_name: 'Rezept-Moderator')
        Role.find_by(name: 'image_moderator')&.update(display_name: 'Bild-Moderator')
        Role.find_or_create_by(name: 'super_moderator') do |role|
          role.display_name = 'Moderator'
        end
      end
    end
  end
end
