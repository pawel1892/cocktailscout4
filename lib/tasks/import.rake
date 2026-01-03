# lib/tasks/import.rake
namespace :import do
  desc "Import all data from the legacy database"
  task all: [:ingredients]

  desc "Import ingredients from the legacy database"
  task ingredients: :environment do
    puts "Importing ingredients..."
    Legacy::Ingredient.find_each do |legacy_ingredient|
      ingredient = Ingredient.find_or_initialize_by(old_id: legacy_ingredient.id)
      ingredient.update!(
        name: legacy_ingredient.name,
        description: legacy_ingredient.description,
        alcoholic_content: legacy_ingredient.alcoholic_content,
        slug: legacy_ingredient.slug,
        created_at: legacy_ingredient.created_at,
        updated_at: legacy_ingredient.updated_at
      )
    end
    puts "Ingredients imported!"
  end
end
