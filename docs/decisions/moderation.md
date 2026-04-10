# Moderation & Safety Decisions

## 2026-01-21 — Report System: Modal UI, No Email

**Decision:** Content flagging uses a `ContentReportModal` (Vue). No emails sent to admins per report.

**Context:** Email spam on each report is noisy and doesn't scale. A moderation queue is better.

**Consequences:**
- Admin moderation queue: `/admin/reports`
- Reports flow: pending → resolved or dismissed
- Admins see a "Pending Reports" badge in their profile menu

---

## 2026-01-22 — Comment Editing: Author Edit Only, Mod/Admin Delete

**Decision:** Comment authors can edit but not delete their own comments. Only Moderators/Admins can delete.

**Context:** Prevents authors from erasing evidence or hiding context after replies are made. Matches forum post policy.

**Consequences:**
- `last_editor_id` tracked on comments — displayed as "Last edited by" in UI
- `authorize_edit!` vs `authorize_delete!` — same pattern as forum posts

---

## 2026-01-18 — Image Moderation: Approved Status Gate

**Decision:** Only "approved" recipe images are shown publicly. Unapproved images are excluded from all public views.

**Context:** User-generated images need moderation before public display.

**Consequences:**
- Always use `approved_recipe_images` scope in public controllers (never `recipe_images` directly)
- Unapproved images do NOT count toward user points
- Gallery and recipe show pages use eager-loaded `approved_recipe_images` to prevent N+1

---

## 2026-01-19 — Private Messages: Per-Participant Soft Delete

**Decision:** A private message deleted by one participant remains visible to the other. Only disappears when both have deleted it.

**Context:** Deleting your own copy of a conversation shouldn't erase the other person's history.

**Consequences:**
- `PrivateMessage` has separate `deleted_by_sender` / `deleted_by_receiver` flags (or similar)
- Scope filters messages per-user — never show deleted messages to the deleting party
- Authorization scopes must enforce user isolation: users only see their own messages

---

## 2026-01-23 — Session Cleanup: 30-Day Cron

**Decision:** Inactive sessions are deleted by cron after 30 days.

**Context:** Sessions accumulate indefinitely without cleanup, growing the sessions table.

**Consequences:**
- Cron job must be configured in deployment (Kamal/cron)
- Users inactive for 30+ days are logged out on next visit
