# CocktailScout4 Project Instructions

## Claude Migration

- The Claude `/ds` skill has been migrated to the repo-local Codex-style skill at `.codex/skills/ds/SKILL.md`.
- When the user types `/ds`, asks for design-system work, or edits/reviews CocktailScout views, partials, components, Tailwind classes, UI styling, or frontend layouts, read `.codex/skills/ds/SKILL.md` before making changes.
- Keep this skill project-scoped. Do not install it as a global Codex skill because it is only relevant to CocktailScout.

## Coding Standards

- Follow Rails conventions and keep the architecture simple, readable, and convention-driven.
- Keep controllers strictly RESTful. Use only the seven standard CRUD actions per controller.
- For non-CRUD behavior, create a specialized controller with descriptive naming and RESTful routing.
- Prefer built-in Rails generators when applicable.
- Keep business logic in models or concerns. Avoid excessive patterns unless requested.

## Frontend And Design System

- Prioritize predefined Tailwind utilities defined via `@utility` in `app/frontend/entrypoints/application.css`.
- Refer to `/design-system` for available components such as buttons, inputs, cards, and tags.
- If a reusable element is needed, create a global Tailwind utility in `application.css` and add a matching example to `app/views/design_system/index.html.erb`.
- Avoid arbitrary Tailwind classes or custom CSS when an existing design-system utility fits.
- Define rank colors and other dynamically interpolated classes as standard CSS, not `@utility`, to avoid Tailwind JIT purging.

## Database Migrations

- Boolean columns with defaults must use `null: false`.
- Keep migration column order:
  1. Foreign keys.
  2. Essential data columns such as slugs, names, and titles.
  3. Other data columns.
  4. Caches and counters.
  5. Legacy or meta columns such as `old_id` and `position`.
  6. Timestamps last.

## Workflow

- Before nontrivial shell work, state the plan or immediate action briefly.
- Do not auto-commit unless explicitly requested.
- Use `git status` and `git diff` to summarize changes before proposing a commit message.
- Write RSpec tests for new features.
- Record non-obvious architectural or design decisions in `docs/decisions/`.
- Use the format `Decision` / `Context` / `Consequences`, matching existing decision entries.

## Technical Context

- Authentication uses Rails 8 native auth with `User`, `Session`, and `Current`.
- Legacy Devise BCrypt hashes remain compatible through `has_secure_password`.
- Frontend uses Vue 3 via Importmaps plus Turbo. Vue components mount inside a single `#app` div.
- Auth state is hydrated from the server-rendered `<meta name="current-user">`, not an API call.
- Testing uses RSpec, FactoryBot, and Shoulda Matchers. Use model specs for unit coverage and request specs for integration coverage. Do not add view specs.
- Factory slugs must use sequences to prevent unique-index flakiness.
- Legacy data imports use `LegacyRecord` for the `cocktailscout3` database and idempotent rake tasks in `lib/tasks/import.rake` with `find_or_initialize_by(old_id: ...)`.
- Legacy user profile data is merged into `users`; content model user foreign keys must be `optional: true` because only active users were imported.

## Project Memory

- Check `docs/decisions/` for architectural decisions and rationale before changing existing patterns.
