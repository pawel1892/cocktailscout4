require_relative "../../lib/bbcode_to_markdown"

namespace :forum do
  desc "Migrate forum post bodies from BBCode to Markdown. Env vars: DRY_RUN=true, OVERRIDE=true"
  task markdown_migration: :environment do
    dry_run  = ENV["DRY_RUN"]  == "true"
    override = ENV["OVERRIDE"] == "true"

    if dry_run
      puts "[DRY RUN] Keine Änderungen werden gespeichert.\n\n"
    else
      puts "Starte BBCode → Markdown Migration#{" (OVERRIDE: bereits migrierte Posts werden erneut konvertiert)" if override}...\n\n"
    end

    converted  = 0
    skipped    = 0
    errors     = 0
    total_done = 0

    ForumPost.unscoped.find_in_batches(batch_size: 500) do |batch|
      batch.each do |post|
        if post.body.blank?
          skipped += 1
          next
        end

        # Skip already-migrated posts unless OVERRIDE=true
        if post.body_bbcode.present? && !override
          skipped += 1
          next
        end

        begin
          markdown = BbcodeToMarkdown.convert(post.body)

          if dry_run
            puts "=== Post #{post.public_id} (id: #{post.id}) ==="
            puts "VORHER: #{post.body.truncate(300)}"
            puts "NACHHER: #{markdown.truncate(300)}"
            puts ""
          else
            post.update_columns(
              body_bbcode: post.body,
              body:        markdown
            )

            total_done += 1
            if (total_done % 1000).zero?
              puts "  #{total_done} Posts konvertiert..."
            end
          end

          converted += 1
        rescue => e
          errors += 1
          puts "FEHLER bei Post #{post.id}: #{e.message}"
        end
      end
    end

    puts "\n#{"[DRY RUN] " if dry_run}Fertig."
    puts "  Konvertiert: #{converted}"
    puts "  Übersprungen (bereits migriert oder leer): #{skipped}"
    puts "  Fehler: #{errors}" if errors > 0
  end
end
