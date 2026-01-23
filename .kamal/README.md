# Kamal Configuration Files

## Secrets Files - GITIGNORED

The following files contain **actual passwords and tokens** and are **gitignored**:

- `secrets-common` - Shared secrets (Docker Hub token, Rails master key)
- `secrets.beta` - Beta-specific passwords
- `secrets.production` - Production-specific passwords

**These files are NOT committed to git.** They contain real credentials.

## Setting Up Secrets

1. Edit `secrets-common`:
   - Add your Docker Hub username
   - Add your Docker Hub token

2. Edit `secrets.beta`:
   - Add your beta server IP address
   - Add strong passwords for beta database

3. Edit `secrets.production` later when setting up production:
   - Add your production server IP address
   - Add strong passwords for production database

See `secrets.example` for a template.

The deployment config files read these values automatically using ERB templates.

## What IS Safe to Commit

- `secrets.example` - Template file showing the format
- Hook samples (*.sample files)
- This README

## Hooks Directory

The `hooks/` directory contains sample hook scripts that can be customized. The `.sample` extension means they're not active. To use a hook, copy it without the `.sample` extension and make it executable.
