# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create roles
Role.find_or_create_by(name: 'admin') { |role| role.display_name = 'Admin' }
Role.find_or_create_by(name: 'forum_moderator') { |role| role.display_name = 'Forum-Moderator' }
Role.find_or_create_by(name: 'recipe_moderator') { |role| role.display_name = 'Rezept-Moderator' }
Role.find_or_create_by(name: 'image_moderator') { |role| role.display_name = 'Bild-Moderator' }
Role.find_or_create_by(name: 'super_moderator') { |role| role.display_name = 'Moderator' }
