# Kamal Deployment Guide

## Quick Start (Beta)

### 1. Configure Secrets

**.kamal/secrets-common**:
```bash
DOCKER_USERNAME=your_dockerhub_username
KAMAL_REGISTRY_PASSWORD=your_docker_hub_token_here
```
Get token at https://hub.docker.com/settings/security

**.kamal/secrets.beta**:
```bash
BETA_SERVER_IP=123.45.67.89
RAILS_MASTER_KEY=$(cat config/credentials/beta.key)
MYSQL_ROOT_PASSWORD=generate_strong_password
COCKTAILSCOUT4_DATABASE_PASSWORD=generate_strong_password
```

The `config/deploy.beta.yml` file reads these values automatically - no editing needed!

### 3. Deploy

```bash
kamal setup -d beta
kamal app exec -d beta 'bin/rails db:migrate'
```

Visit https://beta.cocktailscout.de

---

## Detailed Setup

### Prerequisites

- Server with Docker installed (Kamal can install it)
- Docker Hub account
- SSH access as user `pawel` with restricted passwordless sudo
  - **See SERVER_SETUP.md for detailed server configuration**
- Domain DNS configured (beta.cocktailscout.de → server IP)
- Ports 80 and 443 open in firewall

### Configuration Files

#### Deployment Config: config/deploy.beta.yml

Main configuration file for beta deployment. This file can be committed to git as it uses ERB to read values from secrets files. Contains:
- Docker registry settings
- SSL/domain configuration
- Environment variables
- Database settings

No manual editing needed - all environment-specific values come from secrets files.

#### Secret Files (Gitignored)

These files contain actual passwords and environment-specific values. **Not committed to git**:

- `.kamal/secrets-common` - Shared across all deployments
  - Docker Hub username
  - Docker Hub token

- `.kamal/secrets.beta` - Beta-specific
  - Beta server IP address
  - Rails master key (beta environment)
  - MySQL root password
  - Application database password

- `.kamal/secrets.production` - Production (template for later)
  - Production server IP address
  - Rails master key (production environment)
  - MySQL root password
  - Application database password

Use `.kamal/secrets.example` as a template.

### First Deployment

```bash
# Setup server, database, and deploy app
kamal setup -d beta

# Run database migrations
kamal app exec -d beta 'bin/rails db:migrate'

# Optional: Seed database
kamal app exec -d beta 'bin/rails db:seed'
```

The first visit may take a moment as Let's Encrypt provisions your SSL certificate.

### Subsequent Deployments

```bash
kamal deploy -d beta
```

Kamal automatically loads secrets from `.kamal/secrets-common` + `.kamal/secrets.beta`.

---

## Common Commands

All commands use `-d beta` to target the beta environment:

```bash
# Deployment
kamal deploy -d beta              # Deploy latest changes
kamal rollback -d beta            # Rollback to previous version

# Application
kamal app boot -d beta            # Start application
kamal app stop -d beta            # Stop application
kamal app restart -d beta         # Restart application
kamal app details -d beta         # Show container details
kamal app logs -d beta            # View application logs

# Rails-specific
kamal console -d beta             # Rails console
kamal shell -d beta               # Shell access
kamal dbc -d beta                 # Database console
kamal app exec -d beta 'command'  # Run arbitrary command

# Database accessory
kamal accessory details db -d beta    # Database container details
kamal accessory logs db -d beta       # Database logs
kamal accessory restart db -d beta    # Restart database
```

---

## What's Configured

### Beta Environment

- **Domain**: beta.cocktailscout.de
- **SSL**: Auto-configured with Let's Encrypt
- **Database**: MySQL 8.0 as Kamal accessory
  - `cocktailscout4_beta` - Main database
  - `cocktailscout4_beta_cache` - Solid Cache
  - `cocktailscout4_beta_queue` - Solid Queue
  - `cocktailscout4_beta_cable` - Solid Cable
- **Storage**: Persistent volume for Active Storage files
- **Jobs**: Solid Queue running in Puma process
- **Web Server**: Thruster (production Puma wrapper)
- **Assets**: Vite with Vue.js and Tailwind CSS

### Security

- SSL enforced (force_ssl = true)
- Host authorization enabled
- Database isolated from production
- Secrets gitignored

---

## Troubleshooting

### Check Container Status

```bash
kamal app details -d beta
```

Shows if containers are running and their configuration.

### View Application Logs

```bash
kamal logs -d beta
```

Follow logs in real-time with `-f` flag.

### Check Database

```bash
# Database container status
kamal accessory details db -d beta

# Database logs
kamal accessory logs db -d beta
```

### Access Rails Console

```bash
kamal console -d beta
```

Useful for checking database connections, running queries, etc.

### SSH to Server

```bash
ssh root@YOUR_SERVER_IP

# View running containers
docker ps

# Check Docker network
docker network ls
```

### Common Issues

**SSL Certificate Not Working**
- Let's Encrypt takes a few moments on first visit
- Check DNS is pointing to correct IP
- Ensure ports 80 and 443 are open

**Database Connection Errors**
- Verify database accessory is running: `kamal accessory details db -d beta`
- Check DB_HOST environment variable is set to `cocktailscout4-db`
- Verify passwords in secrets files match

**Build Failures**
- Check Docker Hub credentials in `.kamal/secrets-common`
- Ensure you have permission to push to the image repository
- Check Dockerfile syntax

---

## Production Deployment

Once beta is working and tested:

### 1. Create Production Config

Copy and modify the beta configuration:

```bash
cp config/deploy.beta.yml config/deploy.production.yml
```

Update in `config/deploy.production.yml`:
- Change `BETA_SERVER_IP` to `PRODUCTION_SERVER_IP` (3 places)
- Change `host: beta.cocktailscout.de` to `host: www.cocktailscout.de`
- Change database names from `cocktailscout4_beta*` to `cocktailscout4_production*`
- Change `APP_HOST: beta.cocktailscout.de` to `APP_HOST: www.cocktailscout.de`

### 2. Configure Production Secrets

Edit `.kamal/secrets.production`:
```bash
PRODUCTION_SERVER_IP=your_production_server_ip
RAILS_MASTER_KEY=$(cat config/credentials/production.key)
MYSQL_ROOT_PASSWORD=different_strong_password
COCKTAILSCOUT4_DATABASE_PASSWORD=different_strong_password
```

Use **different passwords and server** from beta. The production master key is already generated.

### 3. Deploy Production

```bash
kamal setup -d production
kamal app exec -d production 'bin/rails db:migrate'
```

### 4. Use Production Commands

All commands work the same, just use `-d production`:

```bash
kamal deploy -d production
kamal logs -d production
kamal console -d production
```

---

## Secret Management

Kamal 2 automatically loads secrets based on destination:

| Command | Loads |
|---------|-------|
| `kamal deploy -d beta` | `.kamal/secrets-common` + `.kamal/secrets.beta` |
| `kamal deploy -d production` | `.kamal/secrets-common` + `.kamal/secrets.production` |

### Security Best Practices

- Secret files are gitignored - never commit them
- Keep backups in secure location (password manager, encrypted storage)
- Use strong, unique passwords for each environment
- Regularly rotate database passwords
- Don't share production credentials

### Team Setup

When a team member needs to deploy:

1. They get server access (SSH key)
2. Copy `.kamal/secrets.example` to create their secret files
3. Get credentials from secure shared location (password manager)
4. Deploy as normal

---

## Database Management

### Access MySQL Directly

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Connect to MySQL
docker exec -it cocktailscout4-db mysql -u root -p
# Enter MYSQL_ROOT_PASSWORD when prompted
```

### Backups

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Backup all databases
docker exec cocktailscout4-db mysqldump -u root -p --all-databases > backup.sql

# Backup specific database
docker exec cocktailscout4-db mysqldump -u root -p cocktailscout4_beta > backup_beta.sql
```

Consider setting up automated backups with cron.

### Restore from Backup

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Restore
docker exec -i cocktailscout4-db mysql -u root -p < backup.sql
```

---

## Architecture Notes

- Single server deployment (beta and production can be on same server or different)
- MySQL runs as Docker container managed by Kamal
- Application runs in Docker container with Thruster web server
- Let's Encrypt handles SSL certificates automatically
- Persistent volumes for database data and uploaded files
- Zero-downtime deployments (Kamal keeps old version running until new one is healthy)

---

---

## Managing Rails Credentials

Each environment has its own encrypted credentials file with a separate encryption key.

### Edit Beta Credentials

```bash
EDITOR=nano rails credentials:edit --environment beta
```

### Edit Production Credentials

```bash
EDITOR=nano rails credentials:edit --environment production
```

### What to Store in Credentials

When you need to add secrets later:

**Email/SMTP Settings:**
```yaml
smtp:
  address: smtp.sendgrid.net
  user_name: apikey
  password: SG.your_sendgrid_api_key
```

**Cloud Storage (S3, Cloudinary, etc.):**
```yaml
aws:
  access_key_id: AKIAIOSFODNN7EXAMPLE
  secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCY
  bucket: cocktailscout-beta  # or cocktailscout-production
```

**Third-Party APIs:**
```yaml
some_api:
  api_key: your_api_key
  api_secret: your_api_secret
```

### Access in Code

```ruby
# In your application code
Rails.application.credentials.smtp[:password]
Rails.application.credentials.aws[:access_key_id]
```

### Security Note

The encryption keys are stored in:
- `config/credentials/beta.key` - Gitignored, used by Kamal via secrets.beta
- `config/credentials/production.key` - Gitignored, used by Kamal via secrets.production

**Keep these key files backed up securely!** If you lose them, you can't decrypt your credentials.

---

## Additional Resources

- Kamal Documentation: https://kamal-deploy.org
- Docker Hub: https://hub.docker.com
- Let's Encrypt: https://letsencrypt.org
- Rails Credentials Guide: https://guides.rubyonrails.org/security.html#custom-credentials
