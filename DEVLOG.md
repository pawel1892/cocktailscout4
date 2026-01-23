# Cocktailscout4 Dev Log

## 2026-01-23 08:30 — Startpage
- **Time spent**: 15min
- **Description**:
	- Added new startpage from scratch with 4 boxes pointing to the content.

## 2026-01-22 23:00 — Recipe Comment Editing & Permissions
- **Time spent**: 1h
- **Description**:
	- **Recipe Comments**: Implemented Edit, Update, and Destroy functionality.
	- **Permissions**: Refactored authorization to allow authors to Edit only, while Moderators/Admins can both Edit and Delete.
	- **History**: Added `last_editor_id` tracking to comments and updated the import task to map legacy edit history.
	- **UI**: Added "Last edited by" metadata display at the bottom of comments and integrated management buttons in the Recipe Show view.
	- **Testing**: Added request and model specs covering the new granular permission logic and editor tracking.

## 2026-01-21 21:30 — Content Reporting System
- **Time spent**: 1h
- **Description**:
	- **Report System**: Implemented a polymorphic `Report` model to handle flagging of any content type (`ForumPost`, `RecipeComment`, `PrivateMessage`).
	- **Admin Dashboard**: Created a dedicated Moderation Queue (`/admin/reports`) for reviewing, resolving, or dismissing reports.
	- **Frontend**:
		- Built `ContentReportModal` (Vue) for a unified reporting UX.
		- Integrated report buttons into Forum Posts, Recipe Comments, and Private Messages.
		- Added dynamic "Admin" link with "Pending Reports" badge to the user profile menu for moderators.
	- **Security**: Restricted admin/report access to users with moderator roles.
- **Outcome**: robust, scalable moderation system without email spam.

---

## 2026-01-21 19:10 — Account Security Features
- **Time spent**: 1h
- **Description**:
	- **Forgot Password**: Re-implemented with native Rails 8 auth, styling, and German localization. Enforced 6-char minimum.
	- **Email Change**: Added unauthenticated confirmation flow (token-based) to support cross-browser verification.
	- **Password Change**: Added secure password change requiring current password verification.
	- **Testing**: Comprehensive request specs for all flows including edge cases.
- **Outcome**: Full self-service account security management.

---

## 2026-01-20 22:24 — Account Confirmation & Mailer Implementation
- **Time spent**: 1h
- **Description**:
	- **Mailer**: Implemented `UserMailer` with multipart (HTML/Text) templates in German. Styled with project colors (#360D0C, #CBB859) and embedded brand logo.
	- **Infrastructure**: Configured `letter_opener` for zero-setup local email previewing.
	- **Confirmation Flow**:
		- Added mandatory email confirmation for new registrations.
		- Implemented `ConfirmationsController` for token verification and resending instructions.
		- Hardened `SessionsController` to block unconfirmed logins with proper format negotiation (HTML/JSON).
	- **UI**: Added "Bestätigung erneut senden" links to both Rails login page and Vue-based `AuthForm`. Added success feedback for AJAX registrations.
	- **Import**: Updated `import:users` to preserve legacy `confirmed_at` status and filter for confirmed users.
	- **Testing**: Added model and request specs covering the full confirmation lifecycle.
- **Outcome**: Secure, professional account activation flow with full support for both traditional and AJAX-based authentication.

---

## 2026-01-19 22:25 — Favorites UI & Filtering
- **Time spent**: 20 min
- **Description**:
	- **Frontend**: Added `FavoriteToggle` to recipe index (next to title) and show pages.
	- **Filtering**: Implemented "Favorites only" filter in recipe index.
	- **Bugfix**: Fixed persistence of the favorites filter when removing other active filters.

---

## 2026-01-19 12:05 — Favorites Feature (Backend & Import)
- **Time spent**: 30 min
- **Description**:
	- **Layout**: Fixed sticky footer implementation (using flex-col/grow) and reduced its height.
	- **Backend**: Implemented polymorphic `Favorite` model (replacing legacy `UserRecipe`) with uniqueness constraints and proper indexing.
	- **Concerns**: Created `Favoritable` concern for easy attachment to models (added to `Recipe`).
	- **Legacy Import**: Added and executed `import:favorites` rake task, successfully migrating 9747 records from `user_recipes`.
	- **API**: Implemented `FavoritesController` with RESTful `create`/`destroy` endpoints paralleling the Rating system.
	- **Testing**: Added comprehensive model specs (associations, uniqueness) and request specs (authentication, isolation).
- **Outcome**: Robust backend foundation for the favorites feature, fully populated with legacy data and ready for frontend integration.

---

## 2026-01-19 06:55 — Private Messaging System Frontend & Testing
- **Time spent**: 30 min
- **Description**:
	- **Frontend Implementation**: Created complete private messaging UI with inbox/sent views, message detail, and compose form (plain text, no BBCode).
	- **User Integration**: Added "Nachricht senden" button to user profile modal for direct messaging from profiles.
	- **Navigation**: Implemented dropdown menu on username in navbar showing "Mein Profil" and "Meine Nachrichten" with unread badge.
	- **Authorization**: Enforced privacy with scopes ensuring users only see their own messages. Messages deleted by one participant remain visible to the other.
	- **Testing**: Comprehensive test suite with 96 passing specs covering model scopes, associations, authorization, soft deletion, and privacy isolation.
- **Outcome**: Fully functional private messaging system with complete privacy protection and excellent test coverage.

---
## 2026-01-18 23:55 — Footer, Legal Pages & Private Messages Backend
- **Time spent**: 45 min
- **Description**:
	- **Footer Implementation**: Created a clean, centered footer containing only "Impressum" and "Datenschutz" links (no year, no branding).
	- **Legal Pages**: Created `PagesController` (`impressum`, `datenschutz`), configured public routes, and added views with non-commercial disclaimer.
	- **Private Messages (Backend)**:
		- Created `PrivateMessage` model, migration, and associations (`sender`, `receiver`).
		- Implemented `import:private_messages` task to migrate legacy messages, preserving timestamps and read status.
	- **Testing**: Added view/request specs for legal pages (passing).
- **Outcome**: Legal pages are live and compliant. Private messaging backend is established and populated with legacy data.

---
## 2026-01-18 16:30 — User Profile Modal Integration & Stats Auto-Update
- **Time spent**: 45 min
- **Description**:
	- **Critical Bug Fix**: Fixed profile modal not mounting in forum pages. Root cause: Missing div wrapper in forum thread view caused premature closing of #app div, pushing modal outside Vue's mount point.
	- **Global Click Handler**: Replaced inline onclick with class-based `.user-profile-trigger` approach for cleaner event delegation.
	- **Navigation Integration**: Made username in navigation header clickable to open own profile modal.
	- **Stats Auto-Update**: Added callbacks to ForumPost, RecipeComment, and Rating models to automatically recalculate user stats on create/destroy.
	- **Testing**: Updated helper specs for class-based approach. All 528 specs passing.
- **Outcome**: Profile modal now works consistently across entire site (forum, navigation, recipes, gallery). User stats update in real-time.

---
## 2026-01-18 14:56 — User Profile System
- **Time spent**: 30 min
- **Description**:
	- Recreated user profile from legacy system with modal-based interface.
	- **Backend**: Implemented `UserProfilesController` with JSON API for show/update actions. Profile data merged into users table (prename, gender, location, homepage, title).
	- **Frontend**: Created `UserProfileModal` (Vue) using `BaseModal` pattern, loaded via AJAX when clicking username badges.
	- **Profile Display**: Shows username with rank-colored icon, points, profile data, statistics (recipes, images, comments, ratings, forum posts, sign-in count), and account info (member since, last active).
	- **Edit Functionality**: Separate `ProfileEditForm` component for own profile only. Authorization prevents editing other users' profiles.
	- **User Badge**: Updated `user_badge` helper to dispatch CustomEvent opening modal instead of linking to #.
	- **Testing**: 23 new RSpec examples covering controller (show/update, authorization, security) and helper (badge rendering, deleted users).
- **Constraints & Decisions**:
	- **No Public Email**: Explicitly removed public email display as requested (privacy-first approach).
	- **Modal vs Page**: Chose modal interface for quick profile access without navigation disruption.
	- **Authorization**: Returns 403 for unauthorized edits (authenticated users), redirects to login for anonymous users.
- **Outcome**: Functional user profiles accessible from any username throughout the site. Secure edit functionality with proper user isolation.

---
## 2026-01-18 14:28 — Legacy MyBar Import
- **Time spent**: 15 min
- **Description**:
	- Created Legacy::UserIngredient model to access legacy user_ingredients table (dimension='mybar').
	- Implemented import:mybars rake task to create 'Meine Hausbar' collections from legacy data.
	- Successfully imported 1,144 collections with ingredient counts ranging from 4 to 269 per user.
- **Outcome**: All active users with legacy mybar data now have their ingredients available in the new system.

---
## 2026-01-18 16:00 — Full-Page Ingredient Management UX
- **Time spent**: 30 min
- **Description**:
	- Replaced modal-based ingredient management with full-page interface using RESTful `edit` action.
	- **Recipe Counts**: Display recipe count next to each ingredient label. Added `recipes` association to Ingredient model.
	- **Sorting**: Added dropdown to sort ingredients alphabetically or by recipe count (most popular first).
	- **Live Updates**: Show doable recipe count in header with link to filtered recipes. Updates automatically after each add/remove.
	- **Backend Fix**: Added explicit `@collection.reload` in ingredients controller to prevent stale association cache causing crashes.
	- **Testing**: Updated Ingredient model specs for new associations. Added IngredientsController specs (53 passing). Fixed nested ingredients controller spec for new response format.
- **Key Decision**: Removed 20-item limit from ingredients endpoint to show all ingredients on management page.
- **Outcome**: Users can efficiently manage large ingredient collections with visual feedback on recipe availability.

---
## 2026-01-17 15:45 — Ingredient Collections ("Meine Bar")
- **Time spent**: 1h 30 min
- **Description**:
	- Implemented multi-collection ingredient management system replacing legacy single "mybar".
	- **Database**: `ingredient_collections` (user-scoped, name/notes/is_default) and `collection_ingredients` join table.
	- **Backend**: RESTful API with nested ingredient management. Includes `doable_recipes` calculation using SQL HAVING clause.
	- **Frontend**: Vue components (IngredientCollections, Create/Edit/ManageIngredientsModal) with reactive composable.
	- **Recipe Filtering**: Added `by_collection` scope using subquery pattern (`WHERE id IN`) to ensure compatibility with existing filters (rating, tag, ingredient, search).
	- **Testing**: 195 passing tests covering CRUD, filtering combinations, and order independence.
- **Key Decision**:
	- Named "ingredient_collections" (not "mybars") to avoid future conflict with real-life bar locations.
	- Fixed grouped query `.count` issue (returns hash) by using `.length` instead.
	- Subquery approach in scope ensures all filters chain together correctly.
- **Outcome**: Users can manage multiple ingredient lists and filter recipes by what they can make.

---
## 2026-01-16 22:57 — Full-Text Search Implementation (Recipes & Forum)
- **Time spent**: 1h
- **Description**:
	- **Database Optimization**: Added MySQL `FULLTEXT` indexes to `recipes(title)`, `forum_threads(title)`, and `forum_posts(body)` for high-performance searching.
	- **Recipe Search**:
		- Integrated search into the main navigation header and recipe index.
		- Implemented `search_by_title` scope with a `LIKE` fallback for transactional test compatibility.
	- **Forum Search**:
		- Created `ForumSearchController` and a dedicated results view.
		- **Deep Linking**: Results now link directly to the specific matching post anchor (`#post-ID`) across paginated threads.
		- **Contextual Snippets**: Displayed hit snippets in search results to help users identify relevant content.
	- **UI/UX**: Updated the site-wide header to use the new recipe search and refined the forum header search form.
	- **Bug Fixes**:
		- Standardized forum post anchors to `post-ID` to ensure reliable browser scrolling.
		- Resolved `current_user` vs `Current.user` scope issues in forum helpers.
	- **Testing**: Added `forum_search_spec.rb` and updated `recipes_spec.rb` with 100% passing results using the test-environment fallback.
- **Outcome**:
	- Significantly improved discoverability of recipes and forum discussions.
	- Professional "deep-link" search experience for the community.

---
## 2026-01-16 17:56 — Recipe Filtering & Tag Navigation
- **Time spent**: 1h
- **Description**:
	- **Filtering Logic**:
		- Added `by_min_rating` (1-10 scale) and `by_ingredient` scopes to the `Recipe` model.
		- Updated `RecipesController#index` to apply filters for ratings, tags, and ingredients.
	- **UI/UX Enhancements**:
		- **Filter Bar**: Added a dedicated section with dropdowns for filtering recipes.
		- **Active Filters Badge**: Implemented a green callout box that lists active filters as removable badges, including an "Alle Filter zurücksetzen" (Reset All) option.
		- **Empty State**: Created a "Keine Rezepte gefunden" view with a reset button for when filters return no results.
		- **Conditional Pagination**: Optimized all paginated views (Recipes, Gallery, Forum) to hide the paginator when content fits on a single page.
	- **Tag System**:
		- **Legacy Routing**: Implemented `/tag/:tag` route for legacy URL compatibility and improved SEO.
		- **DRY Views**: Refactored tag rendering into a reusable `_tag_list` partial with clickable badges.
	- **Testing**:
		- Added model specs for new scopes.
		- Added helper specs for active filter logic.
		- Added request specs covering filtering combinations and the new tag route.
- **Outcome**:
	- Modern, robust filtering system with clear user feedback on active states.
	- Improved navigation through clickable tags and legacy URL support.
	- 100% test coverage for new logic.

---
# Cocktailscout 4 DevLog

## 2026-01-15 20:20 — Responsive Navigation & Breadcrumbs
- **Time spent**: 1h
- **Description**:
	- **Responsive Navigation**: Refactored the application header into a `_header` partial backed by a `NavigationHelper`.
		- **Desktop**: Implemented a hover-based dropdown for "Rezepte" with keyboard/touch support (`group-focus-within`).
		- **Mobile**: Added a robust hamburger menu with an overlay design, featuring nested accordions (using native `<details>`) and an integrated search bar.
		- **Logic**: Used vanilla JavaScript for menu toggling to ensure reliability independent of Turbo/Vue lifecycles.
	- **Breadcrumbs**: Created a comprehensive breadcrumb system.
		- **Architecture**: `BreadcrumbsHelper` for rendering and `ApplicationController` integration for data build-up.
		- **Integration**: Added breadcrumbs to Recipe (Index/Show), Gallery, and full Forum hierarchy (Topics, Threads, Posts).
		- **Mobile Layout**: Stacked breadcrumbs vertically above the user session controls on small screens for better readability.
	- **Forum Navigation**: Updated all forum-related controllers to provide a consistent "Forum" breadcrumb root.
- **Outcome**:
	- Significantly improved mobile usability and wayfinding across the application.
	- Maintainable and flexible navigation structure.

## 2026-01-15 10:47 — Authentication Refinement
- **Time spent**: 1h
- **Description**:
	- Unified login (email/username), hardened registration (mandatory username, email uniqueness), and polished UI/UX (AJAX forms, localized errors, fixed @user initialization).
- **Outcome**:
	- Robust and user-friendly authentication system.

## 2026-01-14 22:30 — User Activity Tracking
- **Time spent**: 10m
- **Description**:
	- **Login Tracking**: Implemented atomic increment of `sign_in_count` upon successful authentication.
	- **Activity Tracking**: Added a global `before_action` to track user activity (`last_active_at`).
	- **Performance**: Throttled activity updates to once every 10 minutes to minimize database writes.
	- **Testing**: Added `UserActivity` request specs to verify login counting and activity tracking logic/throttling.
- **Outcome**:
	- Accurate user engagement metrics.

## 2026-01-14 21:50 — Forum Administration & Polish
- **Time spent**: 45m
- **Description**:
	- **Post Actions UI**: Redesigned post action buttons.
		- Edit: Moved to the left, now an unobtrusive pencil icon (Author/Admin/Mod).
		- Delete: Added trash icon (Admin/Mod only) with confirmation dialog.
		- Quote: Kept as primary action on the right.
	- **Authorization**: Split authorization logic in `ForumPostsController`.
		- `authorize_edit!`: Allows Authors, Admins, and Moderators.
		- `authorize_delete!`: Strict check for Admins and Moderators only (Authors cannot delete their own posts).
	- **Safety**: Added standard JS confirmation (`confirm()`) for deletions since Turbo is not enabled.
	- **Logic**: Implemented `soft_delete_empty_thread` callback in `ForumPost` to automatically hide threads when their last visible post is deleted.
	- **Navigation**: Updated controller to redirect to the Topic view if the Thread was deleted along with the post.
- **Outcome**:
	- Improved moderation tools and safety checks.
	- Self-cleaning forum structure (no empty threads).
	- Robust authorization preventing accidental or unauthorized deletions.

## 2026-01-13 12:45 — Forum Creation, Editing & UI Polishing
- **Time spent**: 1h 30m
- **Description**:
	- **Forum Interaction**: Implemented full CRUD functionality for Forum Threads and Posts.
		- Created `ForumPostsController` and `ForumThreadsController` (create/new actions) with proper routing.
		- Implemented `ForumThreadForm` form object (though simplistic for now) to handle thread creation.
	- **Quoting System**: Implemented "Quote" feature that pre-fills the editor with the original post content wrapped in nested `[quote]` tags.
	- **UI Enhancements**:
		- Improved forum post typography with increased paragraph spacing (`mb-4`).
		- Integrated `BbcodeEditor` Vue component (though not fully wired in backend yet, UI is ready).
		- Wired up "New Thread" and "Reply" buttons in views.
	- **Bug Fixes**:
		- Resolved `ForumThread` model visibility issues (moved methods out of `private`).
		- Fixed syntax error in `ForumThread`.
		- Addressed Rails 8 deprecation warning by using `status: :unprocessable_content`.
	- **Testing**:
		- Added comprehensive `ForumPosts` request specs covering auth, quoting, and CRUD.
		- Fixed `ForumThread` factory to generate unique slugs, resolving flaky tests.
- **Outcome**:
	- Users can now create new threads, reply to topics, and quote other posts.
	- robust test coverage for all new interactions.
	- Clean, readable typography for long-form content.

## 2026-01-13 11:30 — Forum BBCode & Legacy Data Modernization
- **Time spent**: 1h
- **Description**:
	- **Data Modernization**: Critical update to `import:forum` and `import:comments` tasks to replace legacy `<br />` tags with newlines (`\n`). This ensures a "state-of-the-art" clean data storage while allowing Rails' `simple_format` to handle safe HTML rendering.
	- **BBCode Implementation**: Created a robust `BbcodeHelper` from scratch.
		- **Recursive Quotes**: Implemented an iterative regex parser to correctly handle nested `[quote]` tags, which previously broke with standard non-greedy matching.
		- **XSS Protection**: Integrated `ERB::Util.html_escape` at the start of the pipeline to ensure all user input is safe before BBCode transformation.
		- **Smileys**: Migrated 25 legacy smileys to `/public/images/smileys` for reliable serving and updated the helper to map shortcuts (e.g., `:)`, `:D`) to these assets.
		- **Standard Tags**: Support for `[b]`, `[i]`, `[u]`, `[color]`, `[url]`, and `[img]`.
	- **UI/UX**: Added Tailwind utilities for quotes (`quote`, `quote-author`, `quote-content`) in `application.css` and integrated the helper into forum post views.
- **Outcome**:
	- 137,987 forum posts and 21,800 comments cleaned and re-imported.
	- 14 passing RSpec tests for the BBCode helper covering nesting, safety, and all tags.

## 2026-01-12 22:55 — User Comment System
- **Time spent**: 1h 15min
- **Description**:
	- Implemented authenticated comment creation on recipe pages.
	- Vue-based character counter (3000 chars) with color-coded feedback.
	- Inline validation errors (red label/border, preserved input) + flash message system (green/yellow/red).
	- Set 3000 char limit after validating all 21,801 legacy comments (one 2629-char comment from 2012 required accommodation).
	- Fixed pagination links on validation errors by using member route (POST /rezepte/:id/comment) and explicit pagy url parameter.
- **Outcome**:
	- Fully functional with 30 passing tests.
	- Reusable flash message partial for future features.

## 2026-01-12 19:30 — Recipe Image Gallery with Modal & Responsive Layout
- **Time spent**: 40m
- **Description**:
	- Created **RecipeImageGallery** Vue component with navigable modal for recipe images.
	- Features: arrow navigation (← →), keyboard support, thumbnail strip, image counter.
	- Added white background and border around images to handle transparent backgrounds properly.
	- Display author info (user badge) and upload date below modal images.
	- Randomize image order on page load for variety across visits.
	- Responsive layout: vertical (image above ingredients) on sm, horizontal (image right of ingredients) on md+.
	- Fixed horizontal scroll bug in header by making navigation responsive (hidden search on mobile, smaller spacing).
	- Enhanced BaseModal component with configurable `maxWidth` prop.
	- Eager loaded image users to prevent N+1 queries.
- **Outcome**:
	- Interactive image gallery with professional modal viewer.
	- Clean image presentation handling all image formats (transparent, extreme aspect ratios).
	- Mobile-optimized header preventing horizontal overflow.

## 2026-01-12 18:55 — Recipe Show Page Redesign & Comment Pagination
- **Time spent**: 45m
- **Description**:
	- Redesigned recipe show page with mobile-first responsive layout.
	- Implemented stats card with rating control, author badge, views, alcohol content, and volume.
	- Added responsive image gallery showing up to 6 approved images with "+ X weitere Fotos" indicator.
	- Reorganized content hierarchy: title with tags → stats → images → ingredients → preparation → comments.
	- Implemented comment pagination (30 per page) using Pagy's `page_key` option for independent pagination.
	- Enhanced comment styling with gray background boxes and proper date formatting (including year).
	- Updated `user_badge` helper to consistently style deleted users with icon and proper formatting.
	- Added SEO tags for comment pagination with rel="prev"/rel="next".
- **Outcome**:
	- Clean, mobile-friendly recipe detail pages with better information hierarchy.
	- Independent pagination for comments that doesn't conflict with potential future recipe pagination.

## 2026-01-12 17:10 — Cocktail Gallery Redesign & Vue Modal System
- **Time spent**: 20m
- **Description**:
	- Redesigned `/cocktailgalerie` with responsive grid (2-6 columns across breakpoints).
	- Created **BaseModal** component: reusable modal with dark backdrop, close via X/click-outside/Escape.
	- Implemented **ImageModal** and **GalleryViewer**: click images to view large versions (1200x1200) in modal.
	- Recipe title in modal links to full recipe, integrated `user_badge` helper.
	- Increased pagination from 50 to 60 items (divisible by all column counts).
- **Outcome**:
	- Interactive gallery with modal image viewer.
	- Reusable BaseModal for future features.

## 2026-01-12 11:30 — Recipe Index Redesign & Mobile Optimization
- **Time spent**: 1h
- **Description**:
	- **UI/UX**: Replaced the legacy table-based recipe index with a modern, mobile-friendly card layout.
	- **Image Handling**:
		- Implemented `recipe_thumbnail` helper with support for random image selection from approved images.
		- Added SVG placeholder fallback for recipes without approved images.
		- Optimized performance by eager loading `approved_recipe_images` and their attachments (preventing N+1 queries).
	- **Rating Display**:
		- Enhanced rating visibility with a larger, color-coded badge.
		- Moved rating counts outside the badge and standardized layout across screen sizes (larger badges on desktop).
	- **Internationalization**: Added German translations for `visits_count`.
	- **Testing**:
		- Added `RecipesHelperSpec` to verify image selection logic (approved vs. pending vs. placeholder).
		- Updated request specs to align with the new card-based DOM structure.
- **Outcome**:
	- Modern, responsive recipe browsing experience.
	- Reliable image display logic ensuring only moderated content is shown.
	- Improved performance and test coverage.

## 2026-01-11 23:15 — Forum UI Overhaul & Responsive Design
- **Time spent**: 1h 30m
- **Description**:
	- **Responsive UI**: Implemented a mobile-first card layout for forum topics and threads, switching to an optimized table view on desktop (>= 1024px).
	- **Styling**: Standardized all forum links using a unified `link` Tailwind utility and cleaned up the post interface.
	- **Unread Logic Fix**: Added `touch: true` to forum associations to ensure thread/topic timestamps update correctly on new posts, resolving broken unread status tracking.
	- **Optimization**: Refactored `ForumTopicsController` to optimize unread status checks, preventing N+1 queries.
- **Outcome**:
	- Fully responsive, modern forum experience.
	- Reliable unread content tracking.
	- 100% passing test suite.

## 2026-01-11 16:45 — Forum Model Enhancements & UserStat Point Fix
- **Time spent**: 45min
- **Description**:
	- **Forum Hardening**:
		- Added `deleted` boolean flag to `ForumThread` and `ForumPost` with default scopes to automatically exclude deleted content from UI and counts.
		- Added `last_editor` association to `ForumPost` for edit tracking.
		- Updated import tasks to handle `deleted` status and `last_editor` mapping from legacy data.
	- **UserStat Fix**:
		- **Bugfix**: Corrected `UserStat#calculate_points` to only count *approved* recipe images (20pts each), resolving a test failure where unapproved images were incorrectly granting points.
	- **Testing**:
		- Added comprehensive request specs for deleted forum threads and posts, verifying they return 404 or are excluded from listings.
		- Updated `UserStat` specs to explicitly test approved vs. non-approved image point logic.
- **Outcome**:
	- Improved data integrity for forum content.
	- Accurate user point/rank calculation synchronized with image moderation state.
	- 279 passing tests.

## 2026-01-11 14:20 — Forum Read-Only Implementation
- **Time spent**: 45min
- **Description**:
	- Implemented read-only forum with `ForumTopicsController` and `ForumThreadsController` (index/show actions).
	- **Models**: Extended `ForumTopic`, `ForumThread`, and `ForumPost` with methods for counts, last posts, pagination, and unread tracking. Made `user` associations optional to support deleted users.
	- **Views**: Created ERB templates mirroring legacy structure with breadcrumbs, thread listings, and post display partials.
	- **Visit Tracking**: Added `visits_count` to `forum_threads`, integrated `Visitable` trait, imported ~11k legacy visits.
	- **Testing**: 91 passing tests (53 model + 38 request specs) covering all functionality.
- **Constraints & Decisions**:
	- **URL Preservation**: Kept exact legacy URLs (`/cocktailforum`, `/cocktailforum/kategorie/:id`, `/cocktailforum/thema/:id`).
	- **RESTful Structure**: Routed thread listing to `ForumThreads#index` instead of `ForumTopics#show` for cleaner semantics.
	- **Smart Linking**: Authenticated users jump to first unread post when clicking thread links.
- **Outcome**:
	- Full forum history accessible (2,422 threads, ~140k posts).
	- Unread highlighting and visit tracking operational.

## 2026-01-11 13:13 — Schema Refinement & Test Suite Hardening
- **Time spent**: 1h
- **Description**:
	- **Naming Standardization**: Renamed `Recipe#views` to `Recipe#visits_count` to align with the `Visitable` trait and Rails counter-cache conventions.
	- **Schema Integrity**:
		- Enforced `utf8mb4_0900_ai_ci` collation project-wide to resolve CI environment mismatches.
		- Corrected column ordering in the `recipes` table to comply with established standards (moving cache/legacy columns relative to timestamps).
	- **Test Refactoring**:
		- Centralized authentication stubs into a reusable `AuthenticationHelpers` module for request specs.
		- Replaced brittle manual session/cookie stubs with a robust `sign_in` helper.
		- Enhanced `Recipes` request specs with comprehensive sorting (by rating, count, title) and pagination verification.
	- **Maintenance**: Performed a full database reset and re-import to apply collation and column order changes across the entire dataset.
- **Outcome**:
	- 100% consistent and standardized database schema.
	- Cleaner, more maintainable test suite with improved coverage for core listing features.

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