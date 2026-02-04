# Migration Plan: cocktailscout3 → cocktailscout4 (Production)

This document is the step-by-step plan for migrating data from the legacy system
(`cocktailscout3`) to the new Rails 8 application (`cocktailscout4`) and switching
the live domains over.

The import runs locally in development. The `import:*` rake tasks are guarded by
`ensure_development` and will abort if `RAILS_ENV=production`. The production
MySQL accessory runs in a Docker container managed by Kamal, accessible on
`127.0.0.1:3306` on the server. Active Storage files are persisted via a volume
mount at `/home/pawel/cocktailscout4-storage-production:/rails/storage`.

---

## Phase 0 — Preparation

Do these before starting the migration:

- **Reduce DNS TTL.** Lower the TTL on the `cocktailscout.de` and
  `www.cocktailscout.de` DNS records so the switch in Phase 7 propagates quickly.
- **Legacy database.** Confirm that `cocktailscout3` is accessible on your local
  machine via the `legacy` connection in `config/database.yml`.
- **Legacy images.** Locate the image files from the old project on disk. You will
  need to copy them locally in Phase 2.

---

## Phase 1 — Take down the old site

Replace `cocktailscout.de` / `www.cocktailscout.de` with a maintenance page.

No new data can be written to the legacy system from this point on.

---

## Phase 2 — Import locally

The import needs two things on the local machine, not just the database:

1. **Legacy database** — accessible via the `legacy` connection (already configured
   in `config/database.yml`).
2. **Legacy images** — copy the image files from the old project into
   `public/system/recipe_images/` in the local cocktailscout4 checkout. The task
   `import:migrate_images_to_active_storage` reads from exactly that path
   (`public/system/recipe_images/{old_id}/original/{filename}`). Without these
   files the task will report all images as missing.

Then run the full import:

```bash
bin/rake import:all
```

`import:all` resets the local development database, runs all 14 import tasks in
the correct order, and finishes by migrating approved images into Active Storage
(`storage/`). Only approved images are migrated — this is by design.

### What `import:all` runs (in order)

| # | Task | What it does |
|---|------|--------------|
| 1 | `import:ingredients` | Imports ingredients with old_id tracking |
| 2 | `import:users` | Imports confirmed, active users with profiles |
| 3 | `import:roles` | Imports roles and user-role associations |
| 4 | `import:recipes` | Imports recipes with user and ingredient mappings |
| 5 | `import:recipe_images` | Imports image *metadata* (ownership, approval, old_id) |
| 6 | `import:comments` | Imports recipe comments |
| 7 | `import:ratings` | Converts 1–5 star ratings to 1–10 scores |
| 8 | `import:tags` | Imports tags via acts-as-taggable |
| 9 | `import:forum` | Imports forum topics, threads, and posts |
| 10 | `import:private_messages` | Imports private messages |
| 11 | `import:visits` | Imports visits and updates visit counts |
| 12 | `import:favorites` | Imports favorites as polymorphic records |
| 13 | `import:stats` | Recalculates user stats |
| 14 | `import:mybars` | Imports user ingredient collections ("Meine Hausbar") |
| 15 | `import:migrate_images_to_active_storage` | Attaches approved image *files* to Active Storage |

---

## Phase 3 — Verify

```bash
bin/rake verify:all
```

This runs 11 verification tasks that sample and cross-check the imported data
against the legacy database: ingredients, users, recipes, comments, forum,
messages, ratings, tags, visits, favorites, images, roles, mybars.

Then do a manual spot-check in the browser: recipes, images (check
`/cocktailgalerie`), forum, login, etc.

---

## Phase 4 — Deploy data to production

Three things need to get to the production server (`23.88.50.20`). Only the
primary application database is transferred — the cache, queue, and cable
databases are runtime-only and should stay empty.

### 4a — Database

Dump the local development database and import it into the production MySQL
container.

```bash
# On your local machine — dump the development database
mysqldump cocktailscout4_development > cocktailscout4_production.sql

# Copy the file to the server (adjust path as needed)
scp cocktailscout4_production.sql pawel@23.88.50.20:/home/pawel/

# On the server — import into the production database
# Use the root password from .kamal/secrets (MYSQL_ROOT_PASSWORD)
mysql -h 127.0.0.1 -u root -p cocktailscout4_production < /home/pawel/cocktailscout4_production.sql
```

### 4b — Images

Archive the local `storage/` directory (the Active Storage blobs written by the
import) and copy it to the production persistent volume.

```bash
# On your local machine — archive the storage directory
tar czf storage.tar.gz -C storage .

# Copy to the server
scp storage.tar.gz pawel@23.88.50.20:/home/pawel/

# On the server — extract into the production storage volume
cd /home/pawel/cocktailscout4-storage-production
tar xzf /home/pawel/storage.tar.gz
```

### 4c — Restart the app

```bash
kamal app restart
```

---

## Phase 5 — Verify on prod.cocktailscout.de

Before touching any DNS, confirm the new server works end-to-end at
`https://prod.cocktailscout.de`. Check recipes, images, forum, login — anything
that matters. This is the last opportunity to catch issues without affecting users.

---

## Phase 6 — Reconfigure for the new hostname

Update `config/deploy.yml` — two values need to change:

| Key | From | To |
|-----|------|----|
| `proxy.host` | `prod.cocktailscout.de` | `www.cocktailscout.de` |
| `env.clear.APP_HOST` | `prod.cocktailscout.de` | `www.cocktailscout.de` |

`APP_HOST` controls URLs in mailer templates (signup confirmation, password
reset, etc.).

Redeploy:

```bash
kamal deploy
```

This reconfigures kamal-proxy for the new hostname and kicks off Let's Encrypt
cert provisioning for `www.cocktailscout.de`. The cert will only actually issue
once DNS points to the server (Phase 7), but the application container stays
running.

---

## Phase 7 — DNS switch

- Point `www.cocktailscout.de` to `23.88.50.20` (A-record). Kamal handles the
  rest for this domain.
- Set up a **301-Headerweiterleitung** for `cocktailscout.de` → `https://www.cocktailscout.de`
  in the do.de control panel (Domains → Einstellungen). This is a proper HTTP 301
  redirect handled by do.de before traffic reaches your server — no CNAME, no
  code changes needed.
- Let's Encrypt will auto-provision the SSL cert for `www.cocktailscout.de` once
  the A-record resolves.

---

## Phase 8 — Remove prod subdomain

- Delete the `prod.cocktailscout.de` DNS record.

---

## Phase 9 — Cleanup

Once everything is stable:

- Delete the temporary legacy image files from `public/system/recipe_images/`
  locally.
- The `legacy` database connection in `config/database.yml` is no longer needed at
  runtime unless a re-import is planned.
- Remove the local dump file (`cocktailscout4_production.sql`) and archive
  (`storage.tar.gz`) from the server.
