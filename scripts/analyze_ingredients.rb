#!/usr/bin/env ruby
# Analyze ingredients comparison and report problematic cases

require_relative '../config/environment'

COMPARISON_FILE = 'ingredients_comparison.txt'
REPORT_FILE = 'ingredients_analysis_report.txt'

# Check if report exists and has progress
def read_progress
  return 0 unless File.exist?(REPORT_FILE)

  content = File.read(REPORT_FILE)
  if match = content.match(/PROGRESS: Analyzed (\d+) recipes/)
    match[1].to_i
  else
    0
  end
end

# Write or update progress
def update_progress(report_file, analyzed_count, total_count, current_recipe = nil)
  report_file.puts "\n=== PROGRESS: Analyzed #{analyzed_count} / #{total_count} recipes ==="
  report_file.puts "Current: #{current_recipe}" if current_recipe
  report_file.puts "Last updated: #{Time.now}"
  report_file.flush
end

def problematic?(old_display, new_display)
  # Define what makes a case problematic
  return false if old_display == '(no description)' || new_display == '(no data)'

  # Normalize for comparison
  old_norm = old_display.strip
  new_norm = new_display.strip

  # Check various problematic patterns
  problems = []

  # Major differences in content (not just formatting)
  old_words = old_norm.downcase.scan(/[a-zäöüß]+/)
  new_words = new_norm.downcase.scan(/[a-zäöüß]+/)

  # Missing ingredient name
  if new_norm =~ /^\d+[\.,]?\d*\s*(cl|ml|l|TL|EL|Spritzer|Scheiben?|Blätter?)\s*$/ && old_norm.length > 10
    problems << "Missing ingredient name"
  end

  # Extra content in new that wasn't in old (like z.B. Cointreau)
  if new_norm.length > old_norm.length + 20
    extra_words = new_words - old_words
    if extra_words.any? && !extra_words.include?('dünn') && !extra_words.include?('gefrostete')
      problems << "Extra content: #{extra_words.join(', ')}"
    end
  end

  # Completely missing data
  if new_norm == '(no data)' && old_norm != '(no description)'
    problems << "Data lost"
  end

  # Significant word count difference
  if old_words.count > 2 && new_words.count < old_words.count - 2
    problems << "Missing words: #{(old_words - new_words).join(', ')}"
  end

  problems
end

puts "Starting ingredient analysis..."
puts "Comparison file: #{COMPARISON_FILE}"
puts "Report file: #{REPORT_FILE}"
puts ""

unless File.exist?(COMPARISON_FILE)
  puts "Error: #{COMPARISON_FILE} not found"
  exit 1
end

# Read existing progress
start_from = read_progress
puts "Resuming from recipe ##{start_from + 1}" if start_from > 0

# Parse comparison file
recipes = []
current_recipe = nil
current_ingredients = []

File.readlines(COMPARISON_FILE).each do |line|
  if line =~ /^Recipe: (.+)/
    if current_recipe
      recipes << { recipe: current_recipe, ingredients: current_ingredients }
    end
    current_recipe = { title: $1.strip, views: 0, url: '' }
    current_ingredients = []
  elsif line =~ /^Views: (\d+)/
    current_recipe[:views] = $1.to_i if current_recipe
  elsif line =~ /^URL: (.+)/
    current_recipe[:url] = $1.strip if current_recipe
  elsif line =~ /^(.{48})\s*\|\s*(.+)$/
    old_display = $1.strip
    new_display = $2.strip

    # Skip header row
    next if old_display == 'OLD (description)' || old_display.start_with?('---')

    current_ingredients << { old: old_display, new: new_display }
  end
end

# Add last recipe
recipes << { recipe: current_recipe, ingredients: current_ingredients } if current_recipe

total_recipes = recipes.count
puts "Found #{total_recipes} recipes to analyze"
puts ""

# Open report file (append if resuming)
mode = start_from > 0 ? 'a' : 'w'
File.open(REPORT_FILE, mode) do |f|
  if start_from == 0
    f.puts "=== Ingredient Analysis Report ==="
    f.puts "Generated: #{Time.now}"
    f.puts "Analyzing: #{total_recipes} recipes"
    f.puts ""
    f.puts "=" * 100
  end

  recipes.each_with_index do |recipe_data, index|
    # Skip already analyzed recipes
    next if index < start_from

    recipe = recipe_data[:recipe]
    ingredients = recipe_data[:ingredients]

    # Find problematic ingredients
    problems = []
    ingredients.each do |ing|
      issues = problematic?(ing[:old], ing[:new])
      if issues.any?
        problems << { old: ing[:old], new: ing[:new], issues: issues }
      end
    end

    # Only report recipes with problems
    if problems.any?
      f.puts ""
      f.puts "PROBLEM: #{recipe[:title]}"
      f.puts "Views: #{recipe[:views]}, URL: #{recipe[:url]}"
      f.puts "-" * 100

      problems.each do |prob|
        f.puts "  OLD: #{prob[:old]}"
        f.puts "  NEW: #{prob[:new]}"
        f.puts "  Issues: #{prob[:issues].join('; ')}"
        f.puts ""
      end

      f.puts "=" * 100
    end

    # Update progress every 50 recipes
    if (index + 1) % 50 == 0
      update_progress(f, index + 1, total_recipes, recipe[:title])
      print "."
    end
  end

  # Final progress update
  f.puts ""
  f.puts "=" * 100
  f.puts "=== ANALYSIS COMPLETE ==="
  f.puts "Total recipes analyzed: #{total_recipes}"
  f.puts "Completed: #{Time.now}"
  update_progress(f, total_recipes, total_recipes, "DONE")
end

puts ""
puts "✓ Analysis complete!"
puts "  Report: #{REPORT_FILE}"
puts "  Analyzed: #{total_recipes} recipes"
