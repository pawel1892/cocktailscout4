# Migration & Deployment Guide

This document outlines the steps required to deploy the new Rails 8 application (`cocktailscout4`) and migrate data from the legacy system (`cocktailscout3`).

## 1. Prerequisites

### Databases
*   **New Database**: The application uses a standard Rails database (e.g., MySQL/MariaDB).
*   **Legacy Database**: The application requires read access to the legacy `cocktailscout3` database to perform imports.
    *   Ensure `config/database.yml` is configured to connect to the legacy DB (usually via a `legacy` entry or abstract class connection).

### File System (Images)
*   **Legacy Images**: The original image files from the legacy project must be present on the server for the migration to work.
    *   **Destination**: `/public/system/recipe_images` (in the new project root).
    *   *Note*: These files are only needed temporarily for the migration task. Once migrated to Active Storage, they can be removed.

### System Dependencies
*   **Image Processing**: Ensure `imagemagick` or `libvips` is installed on the server for Active Storage variants.
    *   Current config uses `mini_magick` (requires ImageMagick).

## 2. Initial Setup

```bash
# Install dependencies
bundle install

# Setup the new database
bin/rails db:create
bin/rails db:schema:load
```

## 3. Data Import (Order Matters)

Run the following rake tasks in sequence to import data from the legacy database. These tasks are idempotent (using `find_or_initialize_by` with `old_id`) and safely handle the legacy schema reference.

```bash
# 1. Base Data
bin/rake import:ingredients
bin/rake import:users
bin/rake import:recipes

# 2. Associations & Content
bin/rake import:recipe_ingredients
bin/rake import:ratings
bin/rake import:comments

# 3. Image Metadata
# This imports the database records for images (ownership, approval status, old_id)
bin/rake import:recipe_images
```

## 4. Image Migration (Active Storage)

Once the database records are imported, you must migrate the physical image files into Rails Active Storage.

**Pre-check**: Ensure legacy images are located at `public/system/recipe_images`.

```bash
# Migrate approved images to Active Storage
# This reads from public/system and writes to storage/ (AWS S3 or Disk)
bin/rake import:migrate_images_to_active_storage
```

**Verification**:
*   Check `/cocktailgalerie` to see if images appear.
*   Verify the `storage/` directory (or S3 bucket) contains the new files.

## 5. Post-Migration Cleanup

After verifying that all images are correctly serving from Active Storage:

1.  Delete the temporary `public/system/recipe_images` directory.
2.  The `legacy` database connection is no longer strictly required for runtime (unless new syncs are needed).
