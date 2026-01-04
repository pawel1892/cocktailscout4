# Project: Rails Rewrite (Clean & RESTful)

## Context
- Rewriting legacy app from scratch: cocktail recipe database with community functions
- Legacy Schema Reference: db/legacy/schema.sql
- Migration Strategy: Every new table MUST include an `old_id` column (integer/bigint) to facilitate future data imports.

## Coding Standards (DHH/Rails Way)
- Architecture: "DHH Approved" – Keep it simple, prioritize readability and convention over configuration.
- Controllers: Strict REST. Only the 7 standard CRUD actions per controller.
- Expansion: For any non-CRUD action, create a new specialized controller with a descriptive name and proper RESTful routing.
- Prioritize build-in rails generators over hand written code (if applicable)
- Logic: "Fat Model, Skinny Controller" or use Concerns. Avoid over-engineering with excessive patterns unless requested.

## Workflow
- Always propose a plan before executing shell commands.
- Ensure all new migrations include the `old_id` field.

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
- **Ingredients**: Model created, imported, validations added.
- **Users**: Model created, imported (filtered ~2k active from ~38k total), Auth working.
- **Next Steps**:
  - **Recipes**: Create model with associations to User. Import data linking via `old_id`.