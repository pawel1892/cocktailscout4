# Project: Rails Rewrite (Clean & RESTful)

## Context
- Rewriting legacy app from scratch: cocktail recipe database with community functions
- Legacy Schema Reference: db/legacy/schema.sql
- Legacy Code is in: /legacy
  - only use legacy code to see old functionality
  - never reference or copy it
- Migration Strategy: Every new table MUST include an `old_id` column (integer/bigint) to facilitate future data imports.

## Coding Standards (DHH/Rails Way)
- Architecture: "DHH Approved" – Keep it simple, prioritize readability and convention over configuration.
- Controllers: Strict REST. Only the 7 standard CRUD actions per controller.
- Expansion: For any non-CRUD action, create a new specialized controller with a descriptive name and proper RESTful routing.
- Prioritize build-in rails generators over hand written code (if applicable)
- Logic: "Fat Model, Skinny Controller" or use Concerns. Avoid over-engineering with excessive patterns unless requested.

### Frontend & Design System
- **Utilities First**: Prioritize using predefined Tailwind utilities (defined via `@utility` in `application.css`).
- **Kitchen Sink**: Refer to the Design System page (`/design-system`) for available components (buttons, inputs, cards, tags, etc.).
- **Extensibility**: When a new reusable element is required, create a global Tailwind utility in `application.css` and add a corresponding example to the Design System page.
- **Consistency**: Avoid arbitrary Tailwind classes or custom CSS if a design system utility already exists.

### DB Migration Standards
- **Column Ordering**:
  1. Primary Key (`id`) - *Implicit*
  2. Foreign Keys (`user_id`, `category_id`, etc.)
  3. Essential Data Columns (slugs, names, titles)
  4. Other Data Columns
  5. Caches/Counters
  6. Legacy/Meta columns (`old_id`, `position`)
  7. Timestamps (`created_at`, `updated_at`) - *Must be last*

## Workflow
- Always propose a plan before executing shell commands.
- Ensure all new migrations include the `old_id` field.
- When the user ask for a commit message also update the DEVLOG.md in the style of previous entries
- Rspec new features

## Technical Stack & Decisions
- **Authentication**: Rails 8 Native Auth (User/Session/Current).
  - Compatible with legacy Devise BCrypt hashes.
  - Implements `has_secure_password`.
- **Testing**: RSpec + FactoryBot + Shoulda Matchers.
  - Replaced Minitest.
- **Legacy Data**:
  - Connection: `LegacyRecord` (abstract class) connecting to `cocktailscout3`.
  - Import Pattern: Idempotent Rake tasks (`lib/tasks/import.rake`) using `find_or_initialize_by(old_id: ...)`.
  - User Profile: Merged legacy `user_profiles` data into the main `users` table.

## Progress & Status
- See DEVLOG.md for progress that was made
