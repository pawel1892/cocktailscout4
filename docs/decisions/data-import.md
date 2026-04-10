# Data Import & Migration Decisions

## 2026-01-03 — Legacy DB Bridge: Separate Connection

**Decision:** Created a `Legacy` namespace (e.g., `Legacy::User`) connecting to the old cocktailscout3 MySQL database. Import is done via Rake tasks, not migrations.

**Context:** Need to read from old DB during import without corrupting it.

**Consequences:**
- Legacy models live in `app/models/legacy/`
- Import tasks are idempotent: use `find_or_initialize_by(old_id: ...)` — safe to re-run
- `old_id` column kept on new tables for cross-referencing during validation
- Timestamps preserved: always map `legacy.created_at` → new record

---

## 2026-01-04 — Schema Flattening: User Profiles into Users Table

**Decision:** Merged `user_profiles` legacy table directly into the `users` table (prename, gender, location, homepage, title).

**Context:** Separate profile table is unnecessary indirection for this app size.

**Consequences:**
- No `user_profiles` model or table
- Profile fields nullable on `users`

---

## 2026-01-07 — Active Storage for Images (Not Custom Storage)

**Decision:** Used Rails 8 Active Storage for all recipe images.

**Context:** Needed to future-proof for cloud storage and user-generated content. Native Rails solution avoids a custom file serving layer.

**Consequences:**
- `RecipeImage` model kept as a metadata/join entity (approval status, user ownership) — Active Storage handles the actual file
- Image variants use MiniMagick (libvips not available on local dev)
- Legacy images migrated via Rake task mapping old ID-based folder structure to Active Storage blobs

---

## 2026-01-10 — User Points: Recalculate, Not Import

**Decision:** `UserStat` points are recalculated from current DB state (recipes, images, comments, ratings). Legacy point values are NOT imported.

**Context:** Legacy points may not match the new content state (some content excluded during import). Recalculating from current data guarantees consistency.

**Consequences:**
- Forum post points and mybar points were commented out initially (features not yet migrated)
- Running `import:all` must include `recipe_images` or image points will be missing
- Points formula: Recipes×15 + Approved Images×20 + Comments×2 + Ratings×1

---

## 2026-01-13 — BBCode Data Cleanup: Replace `<br />` with Newlines

**Decision:** During `import:forum` and `import:comments`, replace legacy `<br />` tags with `\n` newlines.

**Context:** Legacy stored HTML fragments. New system uses `simple_format` for safe rendering. Storing newlines is cleaner and format-agnostic.

**Consequences:**
- All imported forum posts and comments use `\n` — rendering uses `simple_format`
- Do not store raw HTML in `body` fields; convert on import

---

## 2026-01-17 — Ingredient Collections Named "ingredient_collections" Not "mybars"

**Decision:** The multi-collection ingredient system uses the table name `ingredient_collections`.

**Context:** "mybars" would conflict with a potential future feature for real-world bar locations.

**Consequences:**
- Model: `IngredientCollection`, table: `ingredient_collections`
- The legacy feature was called "Meine Bar" — UX label is fine, DB name is not
