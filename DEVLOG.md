# Cocktailscout 4 DevLog

## 2026-01-11 11:20 — Forum Models & Visitable Trait Implementation
- **Time spent**: 1h
- **Description**:
	- **Forum Architecture**: Implemented `ForumTopic`, `ForumThread`, and `ForumPost` with legacy data import (~140k records).
	- **Visitable Trait**:
		- Created a polymorphic `Visitable` concern to track view counts and last visit timestamps.
		- **Aggregated Tracking**: Implemented an optimized aggregation strategy (one row per User/visitable, one row for Anonymous/visitable) to balance detail and performance.
		- **Atomic Increments**: Used `increment!` with locking to ensure accurate counts under concurrency.
	- **Integration**:
		- Added `track_visit` to `RecipesController#show`.
		- Standardized database collation to `utf8mb4_0900_ai_ci` project-wide to resolve CI issues.
	- **Testing**: 
		- Created shared examples for `Visitable` and integrated them into `Recipe` and `ForumThread` specs.
		- Added request specs to verify visit tracking for both anonymous and authenticated users.
- **Outcome**:
	- Forum history fully migrated.
	- Universal visit tracking system operational and tested.
	- Database schema standardized and re-imported.

## 2026-01-10 23:30 — User Ranks Reimplementation
- **Time spent**: 1h 30m
- **Description**:
	- Reimplemented the legacy `user_ranks` system as a modern `UserStat` model.
	- **Logic**: 
		- Ranks are dynamically calculated from points (0-10 scale).
		- Points are aggregated from user activity: Recipes (15), Images (20), Comments (2), Ratings (1).
	- **UI**: 
		- Ported legacy rank colors to `application.css`.
		- Installed **FontAwesome** (local/npm) for user icons.
		- Created `user_badge(user)` helper to display the standard "Username + Colored Icon" component.
        - Integrated `user_badge` into Recipes (Index/Show), Comments, and Gallery views.
        - **Fix**: Defined rank colors as standard CSS (not `@utility`) to bypass Tailwind JIT purging caused by dynamic string interpolation.
	- **Refactoring**: 
		- Added missing `has_many :recipes` and `has_many :recipe_images` associations to `User` model with `dependent: :nullify`.
		- **Database**: Updated `user_stats` migration to enforce `null: false, default: 0` for `points`. Rebuilt database and re-imported all data to ensure schema integrity.
        - **Fix**: Corrected `import:all` task to include `recipe_images`, ensuring stats calculation includes image points. Migrated 1874 legacy images.
- **Constraints & Decisions**:
	- **Recalculation vs Import**: Decided to *recalculate* points from current data rather than importing legacy point values, ensuring integrity with the new database state.
	- **Missing Data**: Forum Posts and MyBar points are currently commented out until those features are migrated.
- **Outcome**:
	- Fully functional rank system with visual badges.
	- 100% test coverage for point calculation logic.
	- Database reset and cleaned.

## 2026-01-10 20:22 — Role System Implementation & Authorization
- **Time spent**: 30m
- **Description**:
	- Implemented RBAC (Role-Based Access Control) using `Role` and `UserRole` models.
	- **Legacy Import**: Created a migration path for legacy roles, deliberately filtering out the redundant "member" role.
	- **User Extensions**: Added helper methods to the `User` model (`#admin?`, `#forum_moderator?`, etc.).
	- **Authorization**: Implemented helpers in `ApplicationController` (`require_admin!`, etc.) with "Super User" logic for admins.
	- **Design System**: Restricted `/design-system` access to Admins only.
	- **Testing**: 
		- Created Factories with traits.
		- Implemented model specs for roles/users.
		- Added request specs for access control verification.
- **Constraints & Decisions**:
	- **Many-to-Many**: Implemented `has_many :roles, through: :user_roles`.
	- **Clean Slate**: Discarded `member` role; used standard auth for basic access.
- **Outcome**:
	- Role system operational, tested, and integrated into controller layer.

## 2026-01-10 19:27 — Comprehensive Test Suite Implementation

- **Time spent**: 2h
- **Description**:
    - **RuboCop**: Made RuboCop stricter
	- **Test Coverage**: Built a comprehensive test suite for recipe images, ratings, and comments. Achieved **108 passing tests** with a **54.95% code coverage** baseline.
	- **Model Testing**: Unit tests for `RecipeImage` (15), `Rating` (26), and `RecipeComment` (19) covering associations, validations, callbacks, and business logic.
	- **API & Request Specs**:
		- Ratings API: 23 tests covering authentication, user isolation, and CRUD.
		- Gallery: 5 tests for approval filtering and pagination.
	- **Refactoring**: 
		- Moved `rating_badge_class` to a dedicated `RatingsHelper`.
		- Purged empty helpers (`RecipesHelper`, `DesignSystemHelper`).
		- Added 13 helper-specific tests.
	- **Tooling**: Integrated **SimpleCov** with HTML reports, configured to exclude legacy code and standard Rails boilerplate for accurate metrics.
- **Constraints & Decisions**:
	- **Testing Strategy**: Shifted to a Unit + Request spec approach. Removed isolated view specs as they are redundant when request specs verify the full rendering stack.
	- **Auth Stubbing**: Used `allow_any_instance_of` to stub `Current.session` in request specs, bypassing cookie complexity for cleaner integration tests.
	- **Factory Maintenance**: Updated the `Recipe` factory with sequences for slugs to prevent test flakiness caused by duplicate key errors.
	- **Coverage Baseline**: Established a 55% overall target, prioritizing 100% coverage on core business logic (Models/Helpers). Deprioritized Auth controllers for the initial phase.
- **Outcome**:
	- 108 tests passing, zero pending specs.
	- Core business logic (Rating, RecipeImage, RecipeComment) at **100% coverage**.
	- SimpleCov HTML reports active for identifying future test gaps.

---
## 2026-01-08 20:04 — Fixed Image Import
- **Time spent**: 30m
- **Description**:
	- Import used columns that were not in the table anymore
- **Outcome**:
	- RecipeImage import works

---
## 2026-01-08 18:20 — Pagy Upgrade & CI Setup

- **Time spent**: 2h
- **Description**:
	- **Pagy Upgrade**: Performed a major overhaul of the Pagy gem from 9.x to 43.x ("The Leap Version"). Refactored controllers, helpers, and views to accommodate the new API and semantic HTML structure.
	- **CI/CD Pipeline**: Implemented a GitHub Actions workflow covering linting (RuboCop), security (Brakeman, Bundler-Audit), and RSpec testing.
	- **Infrastructure**: Configured the CI environment with MySQL (TCP mapping) and handled Vite/Node.js asset precompilation.
	- **Security Hardening**: Replaced unsafe reflection (`constantize`) in `RatingsController` with a whitelist-based lookup to address Brakeman warnings.
	- **Code Quality**: Optimized RuboCop settings to silence noise (layout/styling) and ignored the `legacy/` directory.
- **Constraints & Decisions**:
	- **Database Collation**: Standardized on `utf8mb4_0900_ai_ci` for the schema. This ensures compatibility between local dev, GitHub runners, and cloud providers while maintaining full emoji support.
	- **CI Connectivity**: Switched to TCP-based database connections (127.0.0.1:3307) in the CI environment to avoid socket conflicts on shared runners.
	- **Legacy Isolation**: Explicitly excluded `/legacy` from all automated scans (RuboCop/Brakeman) to focus maintenance efforts strictly on the new Rails 8 codebase.
- **Outcome**:
	- Pagy 43 is fully integrated and styled.
	- Automated CI pipeline is established and green (Lint, Security, Test).
	- Local and remote test suites are synchronized.

---
## 2026-01-07 11:20 — Recipe Images & Active Storage Migration 
- **Time spent**: 1h 
- **Description**: 
	- Implemented a unified image management system using **Rails 8 Active Storage**. 
	- Migrated ~1.9k legacy approved images from the old physical folder structure into the managed storage system. 
	- Created a public cocktail gallery and integrated dynamic image display into the recipe detail pages. 
- **Constraints & Decisions**: 
	- **Active Storage**: Switched to the native Rails solution to future-proof the app for user-generated content and cloud storage options. 
	- **Image Processing**: Configured **MiniMagick** as the variant processor (fallback due to missing libvips on the local dev system). 
	- **Migration Logic**: Developed a Rake task to map the legacy ID-based folder structure to Active Storage Blobs while preserving metadata (user ownership, approval status). 
	- **Database Schema**: Retained the `RecipeImage` table as a join/metadata entity to support future moderation workflows and community features.
- **Outcome**: 
	- Unified image handling for both legacy assets and future uploads. 
	- Functional cocktail gallery live at `/cocktailgalerie` with automated thumbnail generation. 

---
## 2026-01-06 23:32  — Recipe Tags & View Tracking Analysis

- **Time spent**: 2h
- **Description**:
	- Analyzed legacy view tracking and re-implemented tagging functionality.
	- **Legacy Audit**: Investigated `legacy` codebase to understand the relationship between `Visit` records and `Recipe#views`. Found that user-specific visits were tracked separately and did not sync back to the recipe's view count.
	- **Tagging System**: Re-implemented tagging using `acts-as-taggable-on` (v13.0).
	- **Migration Fixes**: Resolved migration conflicts (indices/FKs) to ensure a clean gem installation.
	- **Data Import**: Created `import:tags` task and migrated tags for ~1.5k recipes.
	- **UI Enhancements**:
		- Added small tag labels (`tag-mini`) under recipe titles on the index view.
		- Enlarged recipe titles for improved visual hierarchy.
		- Optimized database queries using `.includes(:tags)` to prevent N+1 issues.
- **Constraints & Decisions**:
	- **View Tracking**: Decided to use a simple `views` counter directly on the `Recipe` model. Porting the complex legacy `visits` table was deemed unnecessary as the "Who viewed this" feature is no longer required (keeping it Clean/RESTful).
- **Outcome**:
	- Tags are fully functional, migrated, and displayed in the UI.
	- Established a clear, simplified path for view counting via basic increments.

---
## 2026-01-06 20:19 — Design elements & Rating system
- **Time spent**: 3h
- **Description**: 
	- Created tailwind utility for links, forms, boxes, labels etc.
	- Updated kitchen sink to show all design elements
	- Implemented a rating system.
- **Constraints & Decisions**:
	- Ratings: Replaced the abandoned letsrate gem with a custom 1-10 scale polymorphic system to support future extensibility.
	- Authentication: Implemented a "transparent" modal-based login/logout flow to keep users on their current page, while maintaining standard Rails routes as fallbacks.
- **Outcome**:
	- Reactive rating component with dynamic color scaling (Red-Yellow-Green).
	- Complete data parity with the legacy database (~1.5k recipes, ~21k comments, ~17k ratings). 
	- Documented Design System accessible at /design-system.

---
## 2026-01-04 22:30 — Recipe Comments (Read-Only)
- **Time spent**: 15m
- **Description**:
	- Implemented the RecipeComment model and its association with User and Recipe.
	- Added an import task to migrate legacy comments, handling user mapping and optional user association (guests).
	- Updated the Recipe show view to list comments.
- **Constraints & Decisions**:
	- RecipeComment user association is optional to support legacy guest comments or deleted users.
	- Implemented eager loading in RecipesController to avoid N+1 queries when displaying comments.
- **Outcome**:
	- Recipe comments are now visible on the recipe detail page.

---
## 2026-01-04 21:52 — Recipes Controller & Views (Index/Show)
- **Time spent**: 15 m
- **Description**:
	- Implemented RESTful index and show actions for recipes
- **Constraints & Decisions**:
	- Routes mapped to /rezepte as per legacy project requirements.
- **Outcome**:
	- Functional recipe browsing via /rezepte and /rezepte/:slug.

---

## 2026-01-04 15:40 — Recipes Schema & Data Migration

- **Time spent**: 30m
- **Description**:
	- Designed and implemented the new schema for `Recipes` and `RecipeIngredients`.
	- Restructured the entire database migration history to adhere to a new strict column ordering standard (FKs > Data > Caches > Legacy > Timestamps).
	- Implemented idempotent rake tasks for importing recipes and their ingredient associations from the legacy database.
	- Integrated `acts_as_list` gem for managing ingredient ordering.
- **Constraints & Decisions**:
	- **Column Reordering**: Squashed existing migrations to ensure the production-ready schema is perfectly ordered from the start.
	- **Calculation Caches**: Included `total_volume` and `alcohol_content` columns to mirror legacy caches but upgraded types to `decimal` for precision.
	- **Slug Integration**: Ensured all recipes use legacy slugs for URL consistency.
- **Outcome**:
	- Clean, standard-compliant database schema.


---
## 2026-01-04 14:56 — Vue.js Frontend Auth & Integration
- **Time spent**: 45m
- **Description**:
	- Implemented a hybrid "Ajax-first" authentication system using Rails 8 native auth and Vue.js.
    - Created a reusable `useAuth` Vue composable that hydrates user state from a server-rendered meta tag (avoiding initial API calls) and manages reactive login/logout/registration via JSON requests.
    - Updated Rails `SessionsController` and `RegistrationsController` to support JSON formats.
- **Constraints & Decisions**:
	- Hybrid State Hydration: Decided to pass initial user state via `<meta name="current user">` instead of a separate API call on load. This keeps the initial render fast and "flicker-free".
	- Security: Auth actions still rely entirely on Rails' secure `httpOnly` cookies. The frontend state is purely for UI logic (showing/hiding buttons).
- **Outcome**:
	- Users can log in, register, and log out without full page reloads.
	- Vue components react instantly to authentication state changes across the entire app.

---
## 2026-01-04 12:00 — Users import
- **Time spent**: 1.5h
- **Description**:
	- Created User model and added profile fields via migrations.
	- Created idempotent importer for users with timestamp preservation.
	- Rails 8 Native Auth implemented.
	- Created 7 Legacy models to facilitate cross-database data mapping.
- **Constraints & Decisions**:
	- Schema Flattening: Merged legacy user_profiles data (gender, location, etc.) directly into the users table for simplicity.
	- Only import "active users" - meaning having a: 
		- forum_post
		- recipe
		- recipe_image
		- recipe_comment
		- user_recipe (used for favorites)
	- included bcrypt gem for auth
 - **Outcome**:
    - Successfully imported 2,021 active users from a legacy pool of ~38,500.
    - Verified that legacy passwords authenticate successfully in the new system.

---
 ## 2026-01-03 14:30 — Ingredients import
   - **Time spent**: 1h
   - **Description**:
	   - Created Ingredient model and database schema.
	   - Switched test suite from Minitest to RSpec and configured shoulda-matchers.
	   - Implemented a "Legacy" database connection to access the old cocktailscout3 MySQL database.
	   - Created a specialized Rake task to import ingredient data.
   - **Constraints & Decisions**:
	   - Idempotency: Used find_or_initialize_by(old_id: ...) to ensure the importer can be run multiple times without creating duplicates.
	   - Timestamp Preservation: Explicitly mapped legacy created_at and updated_at to the new records to preserve history.
	   - Included old_id column on the new table to facilitate future joins and data verification.
   - **Outcome**:
	   - Successfully imported all ingredients with full metadata and history preserved.

---
## 2025-12-31 14:40 — Project Architecture & Tech Stack 
- **Time spent**: 2h 
- **Description**: 
	- Initialized Rails 8.0 with Tailwind CSS and Vue.js 3.
	- Configured Importmaps and Propshaft to avoid a Node.js build step.
- **Constraints & Decisions**: 
	- Styling: Tailwind CSS (JIT) for utility-first design. 
	- JS: Vue.js 3 via Importmaps (DHH "No-Build" approach). 
	- Architecture: Hybrid setup: Turbo for navigation, Vue for reactive UI logic. 
- **Outcome**: Functional Rails 8 foundation with Tailwind/Vue integration and legacy DB bridge. 

---