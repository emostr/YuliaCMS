---
title: When something goes wrong
description: Common problems and what to do about them.
permalink: /en/troubleshooting/
---

## Installation

### The script stopped part way

Run it again:

```bash
sudo ruby InstallYulia.rb
```

It is idempotent: it skips what is done and carries on from where it stopped.

### "This script must be run with sudo"

The script needs privileges to install packages:

```bash
sudo ruby InstallYulia.rb
```

### "This does not look like Debian"

Yulia is tested on Debian 13. It will most likely work on Ubuntu — the installer offers to continue — but the commands in this documentation may not match. CentOS, Alpine and the rest are not worth attempting.

### Not enough memory

With 1 GB, building the image may not finish. Either add memory in your provider's panel, or turn on a swap file:

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

## Domains and certificates

### The browser warns about the certificate

That usually means the certificate has not been issued yet. Check, in order:

1. Is the domain added in the admin panel, under the right site's Domains?
2. Does `ping your-domain.com` show the server's IP?
3. Are ports 80 and 443 open? Some providers have their own firewall in the control panel.

Then reload after a minute: the certificate is issued on the first request.

### The admin panel opens instead of the site

The domain is not listed on any site, so Yulia does not know what to show.

### The site works over HTTP but not HTTPS

Check that `.env` names the production Caddyfile:

```
CADDYFILE=./caddy/Caddyfile
```

If it says `Caddyfile.local`, certificates are switched off — that is the mode for running on your own machine.

## Signing in

### The phone with the authenticator is lost

On the code screen, type a **recovery code** — the ones issued during setup. Each works once.

Once in, enrol a new app straight away and issue fresh codes from **Account**.

### Both the phone and the codes are lost

You will need to go to the server and clear the second factor from the account:

```bash
cd /opt/yulia
docker compose exec app ./bin/rails runner \
  'u = User.find_by(email: "you@example.com"); u.update!(otp_secret: nil, otp_confirmed_at: nil, recovery_codes: []); puts "second factor cleared"'
```

After that, signing in with the password asks you to enrol an authenticator again.

### "Too many attempts"

That is the brute-force guard: ten failures in a row lock the account for fifteen minutes. Wait it out.

## The site

### A block has disappeared from the page

Most likely it is one of your own blocks and it is broken or switched off. Look under **Blocks**: a Svelte block may have failed to compile, and the compiler's error is shown there.

A broken block is not drawn, but it does not take the rest of the page with it.

### Changes are not visible to visitors

Save was pressed but Publish was not. The editor's header says "unpublished".

### A picture will not upload

Check the size: the default ceiling is 64 MB. It is changed in `.env`:

```
MAX_UPLOAD_MB=128
```

Then run `docker compose up -d` in `/opt/yulia`.

Accepted formats are PNG, JPEG, GIF, WebP, AVIF, SVG and PDF.

### A form does not submit

Check that the page is **published**: submissions are only accepted from published pages.

If nothing happens on submit, htmx may not have loaded. The form should still work the old way, with a page reload.

## Looking at what is happening

```bash
cd /opt/yulia
docker compose ps
docker compose logs --tail 100 app
```

If the application is restarting in a loop, the reason is in those lines.

### Everything is running but the site does not answer

```bash
docker compose restart
```

If that does not help, check whether the disk is full:

```bash
df -h
docker system prune -a   # removes unused images
```

## Where to ask

Describe the problem in [GitHub issues](https://github.com/emostr/YuliaCMS/issues). Include the output of:

```bash
docker compose ps
docker compose logs --tail 50 app
```

Do not post passwords or the contents of `.env`.
