# Forum BBCode → Markdown Migration

This document describes how to deploy and run the forum migration from BBCode to Markdown.

## What changed

- All forum posts are migrated from BBCode to Markdown
- New `MarkdownEditor` component replaces the old `BbcodeEditor`
- Internal wikilinks: `[[recipe:slug]]`, `[[thread:slug]]`, `[[post:id]]`, optionally `[[recipe:slug|Custom Text]]`
- All 25 smileys preserved (`:super:`, `:party:`, `:stoesschen:`, etc.)
- Forum images can now be hosted on the server (uploaded via the editor)
- Original BBCode is preserved in the `body_bbcode` column as a backup

## Deployment steps

### 1. Deploy the new code

```bash
kamal deploy
```

This runs `db:migrate` automatically via the deploy hook, which creates:
- `forum_posts.body_bbcode` column (backup + idempotency marker)
- `forum_images` table

### 2. Verify the migrations ran

```bash
kamal app exec --reuse "bin/rails db:migrate:status | grep forum"
```

You should see both migrations with status `up`.

### 3. Dry-run the BBCode → Markdown conversion

Preview what will be converted before making any changes:

```bash
kamal app exec --reuse "DRY_RUN=true bin/rails forum:markdown_migration"
```

Review the output carefully. Each post shows VORHER (before) and NACHHER (after).

### 4. Run the migration

```bash
kamal app exec --reuse "bin/rails forum:markdown_migration"
```

The task is **idempotent** — posts with `body_bbcode` already set are skipped, so it is safe to re-run if interrupted.

### 5. Verify

Spot-check a few forum threads visually in the browser. Things to verify:

- Bold, italic, links render correctly
- Smileys appear as images
- Quotes render with the `md-quote` style box
- Old `[b]`, `[i]`, `[url]` tags are gone
- `[[recipe:slug]]` links resolve to the correct recipe page

## Rollback

The original BBCode content is preserved in `body_bbcode`. To roll back:

```bash
kamal app exec --reuse "bin/rails runner \"ForumPost.unscoped.where.not(body_bbcode: nil).find_in_batches { |b| b.each { |p| p.update_columns(body: p.body_bbcode, body_bbcode: nil) } }\""
```

Then redeploy the previous release:

```bash
kamal rollback
```

## BBCode conversion reference

| BBCode | Markdown |
|--------|----------|
| `[b]text[/b]` | `**text**` |
| `[i]text[/i]` | `*text*` |
| `[u]text[/u]` | `<u>text</u>` |
| `[color=X]text[/color]` | `text` (color stripped) |
| `[url=href]text[/url]` | `[text](href)` |
| `[img]url[/img]` | `![](url)` |
| `[post=id]text[/post]` | `[[post:id\|text]]` |
| `[thread=slug]text[/thread]` | `[[thread:slug\|text]]` |
| `[quote]text[/quote]` | `> text` |
| `[quote=Author]text[/quote]` | `[quote=Author]text[/quote]` (shortcode) |
| smileys | unchanged |

## New wikilink syntax (going forward)

| Syntax | Renders as |
|--------|-----------|
| `[[recipe:mojito]]` | Link to recipe, title from DB |
| `[[recipe:mojito\|Mein Lieblingsrezept]]` | Link with custom text |
| `[[thread:mein-thema]]` | Link to forum thread |
| `[[post:abc123xy]]` | Link to forum post |
