---
title: Updating and backups
description: How to update Yulia with one button, and what to keep so that nothing is lost.
permalink: /en/updating/
---

## Updating

Connect to the server and run the same script you installed with:

```bash
sudo ruby InstallYulia.rb
```

It sees that Yulia is already installed and shows a menu with **Update**. From there it downloads the new version, rebuilds and restarts on its own. Database changes are applied during startup.

Sites are unreachable for a minute or two while the restart happens. Content, files and settings are untouched.

If something goes wrong, the script says which step it stopped at and **leaves your data alone**. Running it again is safe.

## What to keep

Three things, all on the server.

### 1. The `.env` file

```
/opt/yulia/.env
```

It holds the database password and `SECRET_KEY_BASE`. Lose `SECRET_KEY_BASE` and sessions end, and the stored second-factor secrets can no longer be decrypted: everyone has to enrol their authenticator again.

Copy the file to yourself once and put it in a password manager.

### 2. The database

Pages, settings and form submissions live here:

```bash
cd /opt/yulia
docker compose exec -T postgres pg_dump -U yulia yulia_production | gzip > ~/yulia-$(date +%F).sql.gz
```

### 3. Uploaded files

Pictures and compiled islands:

```bash
docker run --rm \
  -v project-yulia_storage:/data:ro \
  -v ~:/backup \
  alpine tar czf /backup/yulia-files-$(date +%F).tar.gz -C /data .
```

Copy them to your own machine:

```bash
scp root@203.0.113.10:~/yulia-*.gz .
```

## A daily backup

Create `/etc/cron.daily/yulia-backup`:

```bash
#!/bin/sh
# Daily backup of Yulia, kept for a fortnight.
set -e

DEST=/var/backups/yulia
mkdir -p "$DEST"

cd /opt/yulia
docker compose exec -T postgres pg_dump -U yulia yulia_production \
  | gzip > "$DEST/db-$(date +%F).sql.gz"

cp /opt/yulia/.env "$DEST/env-$(date +%F)"

# Copies older than a fortnight only take up space.
find "$DEST" -type f -mtime +14 -delete
```

Make it executable:

```bash
chmod +x /etc/cron.daily/yulia-backup
```

> A backup on the same server protects you from a mistake, not from losing the server. Take a copy to your own machine or to cloud storage at least monthly.

## Restoring

From a database backup:

```bash
cd /opt/yulia
gunzip -c ~/yulia-2026-09-03.sql.gz | \
  docker compose exec -T postgres psql -U yulia -d yulia_production
docker compose restart app
```

Restore onto **the same version of Yulia** the backup was taken from, or the schema may not match.

## Stopping and starting

Through the installer's menu — **Stop** and **Update** — or by hand:

```bash
cd /opt/yulia
docker compose down     # stop: sites go offline
docker compose up -d     # start again
```

## Seeing what is happening

```bash
cd /opt/yulia
docker compose ps                    # what is running
docker compose logs -f app           # the application log
docker compose logs --tail 50 caddy  # the web server log
```

The same information, more briefly, is in the installer's **Status** and **Recent log** screens.
