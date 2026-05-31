class AddWikiEditorRole < ActiveRecord::Migration[8.1]
  def up
    Role.find_or_create_by!(name: "wiki_editor") do |role|
      role.display_name = "Wiki-Editor"
    end
  end

  def down
    Role.find_by(name: "wiki_editor")&.destroy
  end
end
