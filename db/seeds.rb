# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Load the committed sample-data bundle (recipes, forum threads, wiki articles, fabricated
# users, including its own roles.yml) on a genuinely fresh development DB, so
# `bin/rails db:prepare` gives new contributors a working local copy without needing access to
# the production DB/asset mirror. Must run before the plain role seeding below, since it checks
# that `roles` (among other tables) is still empty.
if Rails.env.development? && ENV["SKIP_SAMPLE_DATA"].blank? && Recipe.count.zero?
  Rake::Task["sample_data:import"].invoke
end

# Create roles (idempotent no-op if sample_data:import already created them above)
Role.find_or_create_by(name: 'admin') { |role| role.display_name = 'Admin' }
Role.find_or_create_by(name: 'forum_moderator') { |role| role.display_name = 'Forum-Moderator' }
Role.find_or_create_by(name: 'recipe_moderator') { |role| role.display_name = 'Rezept-Moderator' }
Role.find_or_create_by(name: 'image_moderator') { |role| role.display_name = 'Bild-Moderator' }
Role.find_or_create_by(name: 'super_moderator') { |role| role.display_name = 'Moderator' }
Role.find_or_create_by(name: 'wiki_editor') { |role| role.display_name = 'Wiki-Editor' }
