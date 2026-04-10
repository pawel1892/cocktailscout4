# Testing Decisions

## 2026-01-03 — RSpec Over Minitest

**Decision:** Switched to RSpec with shoulda-matchers. Minitest removed.

**Context:** RSpec is more expressive for model specs; shoulda-matchers reduce boilerplate for validations/associations.

**Consequences:**
- All specs in `spec/` — no `test/` directory used
- shoulda-matchers configured in `spec/support`

---

## 2026-01-10 — Strategy: Unit + Request Specs (No View Specs)

**Decision:** Testing approach is Model specs (unit) + Request specs (integration). View specs are not used.

**Context:** Request specs verify the full rendering stack end-to-end. Isolated view specs duplicate this without adding confidence.

**Consequences:**
- Don't write `spec/views/` specs
- Request specs cover: authentication gates, response codes, rendered content, authorization

---

## 2026-01-10 — Auth Stubbing: allow_any_instance_of for Current.session

**Decision:** Request specs stub auth via `allow_any_instance_of` on `Current.session`, not by manipulating cookies directly.

**Context:** Cookie-based session stubs are brittle and environment-sensitive. A centralized `sign_in` helper is cleaner.

**Consequences:**
- `sign_in(user)` helper defined in `spec/support/authentication_helpers.rb`
- Include `AuthenticationHelpers` in request spec config

---

## 2026-01-10 — Coverage: 100% on Core Logic, Baseline on Controllers

**Decision:** SimpleCov configured with 55% overall baseline. Core business logic (Models, Helpers) targeted at 100%. Auth controllers deprioritized initially.

**Context:** Not all code is equally risky. Focus effort on rating, image moderation, and comment logic.

**Consequences:**
- SimpleCov HTML reports in `coverage/` — check when adding new business logic
- Legacy code excluded from coverage reports

---

## 2026-01-16 — Search Specs: LIKE Fallback for Test Environment

**Decision:** Recipe search uses MySQL `FULLTEXT` index in production, but falls back to `LIKE` in the test environment (transactional tests don't populate FULLTEXT indexes).

**Context:** MySQL FULLTEXT indexes require a commit before they're queryable. Test suite uses transactions that roll back — FULLTEXT never gets data.

**Consequences:**
- `search_by_title` scope detects test environment and uses `LIKE` automatically
- Forum search tests follow the same pattern
- Do not use `FULLTEXT` in specs directly

---

## 2026-01-13 — Factory Slugs: Sequences to Prevent Flakiness

**Decision:** `ForumThread` and `Recipe` factories use sequences for slug generation.

**Context:** Duplicate slug values caused intermittent unique index violations in parallel/ordered test runs.

**Consequences:**
- Any factory for a model with a unique slug column must use a sequence
- `FactoryBot.create(:recipe)` is safe to call multiple times in the same test suite run
