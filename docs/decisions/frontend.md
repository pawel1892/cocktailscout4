# Frontend Decisions

## 2026-01-04 — Auth State: Meta Tag Hydration

**Decision:** Vue reads initial auth state from `<meta name="current-user">` (server-rendered), not a `/api/me` call.

**Context:** Avoids flicker on load. Auth security still relies on httpOnly cookies.

**Consequences:**
- `useAuth` composable reads from meta tag on mount
- Frontend auth state is UI-only — never use it for authorization logic server-side

---

## 2026-01-12 — BaseModal Component: Reusable Foundation

**Decision:** Created `BaseModal` (Vue) with dark backdrop, close via X/click-outside/Escape. All modals extend this.

**Context:** Gallery, profile, reporting, ingredient management all need modals. DRY foundation prevents inconsistency.

**Consequences:**
- Use `BaseModal` for all new modal UIs — don't build modals from scratch
- Supports configurable `maxWidth` prop

---

## 2026-01-13 — BBCode: Iterative Regex for Nested Quotes

**Decision:** `BbcodeHelper` uses iterative regex parsing (not recursive) for `[quote]` tags.

**Context:** Standard non-greedy regex breaks on nested `[quote][quote]...[/quote][/quote]` patterns, which appear in real legacy data.

**Consequences:**
- XSS protection via `ERB::Util.html_escape` runs first, before any BBCode transformation
- Pipeline order: escape HTML → parse BBCode → allow safe transformations
- 25 legacy smileys served from `/public/images/smileys/` (not CDN)

---

## 2026-01-15 — Navigation: Vanilla JS for Menu Toggle (Not Turbo/Vue)

**Decision:** Hamburger menu toggle uses vanilla JavaScript, not Turbo or Vue.

**Context:** Turbo lifecycle and Vue mount timing caused intermittent failures with menu state. Vanilla JS is always available.

**Consequences:**
- Navigation JS must remain independent of Vue mount lifecycle
- Desktop dropdown uses CSS `group-focus-within` (keyboard/touch safe, no JS needed)

---

## 2026-01-18 — User Profile: Modal, Not Page

**Decision:** User profiles open in a modal (via AJAX) when clicking a username badge, not via a dedicated page navigation.

**Context:** Quick profile access without disrupting the user's current context (reading a recipe, browsing forum).

**Consequences:**
- `UserProfileModal` loaded via AJAX — not server-rendered on the page
- Username badges dispatch a `CustomEvent` to open the modal (class-based: `.user-profile-trigger`)
- Profile edit (`ProfileEditForm`) is own profile only; returns 403 for others, redirect for anonymous

---

## 2026-01-18 — Vue Mount Point: Single #app Div

**Decision:** All Vue components mount inside a single `#app` div in the layout.

**Context:** Standard Vue SPA pattern adapted for Rails hybrid.

**Consequences:**
- Every view must have its content inside `#app`
- A missing or prematurely closed `#app` div will silently break all Vue on that page (happened in forum thread view — missing wrapper caused the div to close early)
- User profile modal must be inside `#app` or it won't mount

---

## 2026-01-16 — Recipe Images: Random Order on Load

**Decision:** Recipe images are randomized on page load (not sorted by upload date).

**Context:** Variety across visits — prevents the same image always appearing first.

**Consequences:**
- Cannot rely on image display order being stable across page loads
- Gallery thumbnail strip order will vary per visit

---

## 2026-01-12 — Comment Pagination: Independent with page_key

**Decision:** Comment pagination uses Pagy's `page_key` option so it doesn't conflict with recipe-level pagination.

**Context:** Recipe show page may paginate other content (images, etc.) in future. Separate keys prevent conflicts.

**Consequences:**
- Comment page param: `comment_page` (or whatever `page_key` is set to)
- Use this pattern whenever two paginated resources appear on the same page

---

## 2026-01-16 — Rank Colors: Standard CSS, Not Tailwind @utility

**Decision:** User rank colors defined as standard CSS classes in `application.css`, not as Tailwind `@utility` or arbitrary values.

**Context:** Tailwind JIT purges dynamically interpolated class strings (e.g., `rank-color-#{rank}`). Static CSS survives purging.

**Consequences:**
- Do not move rank color classes into Tailwind config or `@utility` — they will be purged
- Any dynamic class string injection requires the same standard CSS approach
