# Architecture Decisions

## 2025-12-31 — Core Tech Stack: Rails 8 + Tailwind + Vue.js (Hybrid)

**Decision:** Rails 8 with Tailwind CSS (JIT), Vue.js 3 via Importmaps, Turbo for navigation.

**Context:** Needed to migrate a legacy app while avoiding a heavy Node.js build step. DHH's "No-Build" approach fit the team size and complexity.

**Consequences:**
- Turbo handles navigation; Vue handles reactive UI islands (ratings, modals, forms)
- No webpack/esbuild — Importmaps + Propshaft only
- Vue components are mounted on `#app` — missing that div in any view breaks all Vue on that page (caused a real bug in forum views)

---

## 2026-01-11 — Database Collation: utf8mb4_0900_ai_ci

**Decision:** Standardized all tables on `utf8mb4_0900_ai_ci`.

**Context:** CI environment mismatches caused test failures when local and GitHub runner collations differed. Also needed full emoji support.

**Consequences:**
- New migrations must specify this collation explicitly
- Required a full DB reset + re-import when introduced
- Resolves sort order and comparison issues between environments

---

## 2026-01-04 — URL Preservation: /rezepte for Recipes

**Decision:** Routes mapped to `/rezepte` (and `/cocktailgalerie`, `/cocktailforum`) matching legacy URLs exactly.

**Context:** Legacy SEO link juice and bookmarks; users expect these URLs.

**Consequences:**
- Do not rename these routes
- Legacy slug format preserved in `recipes.slug` column

---

## 2026-01-06 — View Tracking: Simple Counter, Not Visit Table

**Decision:** Used a simple `visits_count` increment on `Recipe` (and later `ForumThread`). Did not port the legacy `visits` table with per-user tracking.

**Context:** The "Who viewed this recipe" feature is not required. Porting the complex legacy table was unnecessary complexity.

**Consequences:**
- `visits_count` is an approximate counter, not a per-user audit trail
- The `Visitable` concern handles aggregated tracking (one row per user/visitable) for authenticated + anonymous users

---

## 2026-01-08 — CI Database Connection: TCP Not Socket

**Decision:** CI uses `127.0.0.1:3307` (TCP) instead of a socket for MySQL.

**Context:** GitHub Actions shared runners had socket conflicts.

**Consequences:**
- `.github/workflows` and `database.yml` for CI must use TCP/port-based config
