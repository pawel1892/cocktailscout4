# Comments Redesign Plan

## Problem

The current comment section sorts everything by `created_at DESC`. Valuable comments
(brand recommendations, preparation tips, ingredient alternatives) get buried over time
in conversational noise.

## Solution

### Top-level comments
- **Votable** — users can upvote comments
- **Sorted by votes** by default (not by date)
- **Taggable by mods** — tags like "Markenempfehlung", "Alternative", "Zubereitungstipp"
- **Filterable by tag** — users can filter to see only a specific type of comment

### Replies
- Single level only — you can reply to a top-level comment, but not to a reply
- Sorted chronologically (keeps conversations intact)
- No votes, no tags
- Tucked underneath their parent comment

## Data Model Changes

- Add `parent_id` (nullable FK to `comments`) — top-level comments have `NULL`
- Add votes (either a `votes` counter column or a separate `comment_votes` join table)
- Add a `comment_tags` table (mod-managed, many-to-many with comments)

## Behavior Rules

- Only top-level comments are votable and taggable
- Replies preserve natural conversation order
- The structure guides user behavior: useful tip → top-level, reaction → reply

## UI / UX

- Default view: top-level sorted by votes, replies collapsed or shown inline below parent
- Tag filter bar above comments (only shown when tags exist on that recipe)
- Reply button on top-level comments only
