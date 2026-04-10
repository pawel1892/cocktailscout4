# Authentication Decisions

## 2026-01-04 — Rails 8 Native Auth (Not Devise)

**Decision:** Used Rails 8's built-in authentication generator (`rails generate authentication`).

**Context:** Devise adds significant complexity. Rails 8 native auth covers the needed cases with less magic.

**Consequences:**
- Auth is in `app/models/session.rb`, `app/controllers/sessions_controller.rb`
- Sessions cleaned up by cron after 30 days of inactivity
- Passwords use bcrypt — legacy passwords still authenticate (same algorithm)

---

## 2026-01-04 — Hybrid State Hydration: Meta Tag, Not API Call

**Decision:** Initial auth state passed to Vue via `<meta name="current-user">` server-rendered tag. No separate API call on load.

**Context:** A separate `/api/me` call on every page load causes visible flicker and unnecessary latency.

**Consequences:**
- `useAuth` composable reads from the meta tag on mount
- Security: actual auth still relies on `httpOnly` cookies — the meta tag is UI-only
- Vue state is for showing/hiding buttons; never trust it server-side

---

## 2026-01-20 — Email Confirmation: Mandatory for New Registrations

**Decision:** New users must confirm email before logging in. Token-based, with resend option.

**Context:** Standard security practice. Legacy system had confirmation too.

**Consequences:**
- `SessionsController` blocks unconfirmed logins (with proper HTML/JSON format negotiation)
- Legacy imported users: `confirmed_at` preserved from legacy data
- `UserMailer` sends German-language multipart (HTML + text) confirmation emails

---

## 2026-01-21 — Email Change: Unauthenticated Token Flow

**Decision:** Email change confirmed via token sent to new address, works without being logged in (cross-browser).

**Context:** Users might start the change on desktop, open the confirmation email on mobile.

**Consequences:**
- Token-based flow, not session-bound
- Cannot simply check `current_user` in the confirmation action

---

## 2026-01-04 — Only Import Active Users (Not All 38,500)

**Decision:** Imported only users who have at least one: forum post, recipe, recipe image, comment, or favorite (`user_recipe`). Result: 2,021 users out of ~38,500.

**Context:** Bulk of legacy accounts are inactive/spam. Importing all would pollute the user table.

**Consequences:**
- Some historical content (comments, posts) may reference users not in the DB — use optional associations (`optional: true`) for all user FKs on content models
- Do not assume a legacy `user_id` maps to an existing `User` record
