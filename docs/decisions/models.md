# Model Design Decisions

## 2026-01-06 — Ratings: Custom 1–10 Polymorphic System (Not letsrate Gem)

**Decision:** Built a custom `Rating` model (1–10 scale, polymorphic) instead of using the `letsrate` gem.

**Context:** `letsrate` is abandoned. Needed future extensibility (rating other content types beyond recipes).

**Consequences:**
- `Rating` is polymorphic: `rateable_type` + `rateable_id`
- Scale is 1–10 (not 1–5 stars) — UI shows color-scaled badge (red → yellow → green)
- `RatingsController` uses a whitelist lookup (not `constantize`) to avoid security issues flagged by Brakeman

---

## 2026-01-11 — Forum Content: Soft Delete with Default Scope

**Decision:** `ForumThread` and `ForumPost` have a `deleted` boolean flag with a default scope that excludes deleted records.

**Context:** Moderators need to delete content without permanent data loss. Empty threads auto-hide.

**Consequences:**
- Default scope: `where(deleted: false)` — always active; use `.unscoped` carefully
- `soft_delete_empty_thread` callback: when last visible post deleted, thread is auto-soft-deleted
- Controller redirects to topic view if thread was deleted along with last post

---

## 2026-01-11 — Forum Authorization Split: Edit vs Delete

**Decision:** Authors can edit their own posts but cannot delete them. Only Admins and Moderators can delete.

**Context:** Prevents authors from scrubbing content after others have replied to it.

**Consequences:**
- Two separate authorization methods: `authorize_edit!` (author + admin + mod) and `authorize_delete!` (admin + mod only)
- This is intentional — do not add author delete permission

---

## 2026-01-14 — Activity Tracking: Throttled to 10 Minutes

**Decision:** `last_active_at` updates are throttled — only written if the last update was >10 minutes ago.

**Context:** Tracking every request would cause heavy DB write load.

**Consequences:**
- `last_active_at` precision is ~10 minutes, not per-request
- Implemented as a `before_action` in `ApplicationController`

---

## 2026-01-17 — Recipe Filter Scopes: Subquery Pattern

**Decision:** The `by_collection` scope uses a `WHERE id IN (subquery)` pattern.

**Context:** Direct joins with the existing filter chain (rating, tag, ingredient, search) caused query conflicts. The subquery ensures all filters compose correctly.

**Consequences:**
- All `Recipe` filter scopes should use this subquery pattern for compatibility
- Grouped query `.count` returns a hash — use `.length` instead when results are already loaded

---

## 2026-01-19 — Favorites: Polymorphic Favoritable Concern

**Decision:** `Favorite` is polymorphic. `Favoritable` concern can be added to any model.

**Context:** Future content types (e.g., forum threads, cocktail guides) may also need favorites.

**Consequences:**
- Currently only `Recipe` includes `Favoritable`
- Replaces legacy `UserRecipe` table — imported 9,747 records

---

## 2026-01-21 — Content Reports: Polymorphic Report Model

**Decision:** `Report` is polymorphic — can flag `ForumPost`, `RecipeComment`, or `PrivateMessage`.

**Context:** Single moderation queue for all content types; no email spam on each report.

**Consequences:**
- Admin moderation queue at `/admin/reports`
- Reports have states: pending → resolved or dismissed
- Private messages are soft-deleted per-participant (each side controls their own view)

---

## 2026-01-11 — User Stats: Callbacks on Content Models

**Decision:** `UserStat` is recalculated via callbacks on `ForumPost`, `RecipeComment`, and `Rating` (create/destroy).

**Context:** Stats need to stay current in real-time without a background job.

**Consequences:**
- Any new content type that contributes to points needs a callback wired to `UserStat#recalculate`
- Approved images use `approved_recipe_images` scope — unapproved do not grant points

---

## 2026-01-12 — Comment Character Limit: 3000

**Decision:** `RecipeComment` max length is 3,000 characters.

**Context:** Validated against all 21,801 legacy comments. The longest was 2,629 characters (from 2012). 3,000 gives headroom without being arbitrary.

**Consequences:**
- Do not reduce this limit — it would break legacy content
- Vue character counter shows color-coded feedback as users approach the limit
