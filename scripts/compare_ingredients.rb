#!/usr/bin/env ruby
# Compare old and new ingredient displays for all recipes

require_relative '../config/environment'

puts 'Generating ingredients comparison...'
puts ''

recipes = Recipe.joins(:recipe_ingredients)
  .includes(recipe_ingredients: [ :ingredient, :unit ])
  .order('visits_count DESC')
  .distinct

output_file = 'ingredients_comparison.txt'

File.open(output_file, 'w') do |f|
  f.puts '=== Recipe Ingredients: Old vs New Display ==='
  f.puts "Generated: #{Time.now}"
  f.puts 'Ordered by: Most viewed recipes first'
  f.puts ''
  f.puts '=' * 100

  recipes.each_with_index do |recipe, index|
    f.puts ''
    f.puts "Recipe: #{recipe.title}"
    f.puts "Views: #{recipe.visits_count}"
    f.puts "URL: /rezepte/#{recipe.slug}"
    f.puts '-' * 100
    f.puts '%-50s | %s' % [ 'OLD (description)', 'NEW (formatted display)' ]
    f.puts '-' * 100

    recipe.recipe_ingredients.order(:position).each do |ri|
      # Old style: just the description
      old_display = ri.old_description || ri.description || '(no description)'

      # New style: formatted_amount + ingredient_name + optional additional_info
      if ri.amount.present?
        new_display = "#{ri.formatted_amount} #{ri.formatted_ingredient_name}"
        new_display += " (#{ri.additional_info})" if ri.additional_info.present?
      else
        new_display = ri.formatted_amount || '(no data)'
      end

      f.puts '%-50s | %s' % [
        old_display.truncate(48),
        new_display.truncate(48)
      ]
    end

    f.puts '=' * 100

    # Progress indicator
    print '.' if (index + 1) % 50 == 0
  end

  f.puts ''
  f.puts "Total recipes: #{recipes.count}"
end

puts ''
puts "✓ Comparison file created: #{output_file}"
puts "  Total recipes: #{recipes.count}"
