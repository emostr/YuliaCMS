---
title: Installation
description: From an empty server to a working Yulia, including installing Debian if this is your first time.
permalink: /en/install/
---

Installation takes about fifteen minutes, ten of which are spent waiting. You need to know nothing in advance: if you have never installed Linux, start with the first section.

## What you need

- **A server.** The cheapest VPS will do: 2 GB of memory, 10 GB of disk. That is a few dollars a month at any hosting provider.
- **A domain**, for example `example.com`. Buy it wherever you bought the server, or at any registrar.
- **Half an hour.**

> The sites you build will live on this same server. You do not need a second server for a second site.

## Step 1. Debian on the server

Yulia targets **Debian 13 (Trixie)**. Not Ubuntu, not CentOS — Debian specifically, so that every command in this documentation matches what happens on your machine.

### If you rent a VPS

This is the easy path, and the recommended one. When creating the server, the provider asks which operating system to use: choose **Debian 13**, 64-bit. A minute or two later the server is ready and the provider shows you:

- an **IP address** — four numbers separated by dots, such as `203.0.113.10`;
- the **root password**, or an offer to upload an SSH key.

There is nothing else to do in the provider's panel.

### If you are installing Debian yourself

You only need this if the machine is physically yours.

1. Download the image from [debian.org/download](https://www.debian.org/download) — a file named something like `debian-13.x.x-amd64-netinst.iso`.
2. Write it to a USB stick: [Rufus](https://rufus.ie) on Windows, `dd` on macOS and Linux, or [balenaEtcher](https://etcher.balena.io) on any of them.
3. Boot the machine from the stick. Usually that means pressing <kbd>F12</kbd>, <kbd>F2</kbd> or <kbd>Del</kbd> during startup; the machine itself says which in its first few seconds.
4. Choose **Install**, not Graphical install — it adds nothing here.
5. The installer asks for language, country and keyboard layout. Answer as you like.
6. **Hostname** — anything, such as `yulia`. The domain field can be left empty.
7. Set a root password and write it down. You may add an ordinary user as well.
8. **Partitioning** — choose "Guided, use entire disk". Anything already on the disk is lost.
9. **Software selection** — untick everything except **SSH server** and **standard system utilities**. A desktop on a server does nothing but eat memory.
10. Agree to install the GRUB bootloader to the disk. Done.

## Step 2. Point the domain at the server

This is the step people most often get wrong, so do it **before** running the installer.

Decide which address the admin panel will answer at. A subdomain is the usual choice: `admin.example.com`.

In your registrar's control panel, find **DNS records** and add:

| Field | Value |
|---|---|
| Type | `A` |
| Name (host) | `admin` |
| Value | your server's IP address |
| TTL | leave the default |

Save. The change spreads across the internet in anywhere from a minute to a few hours — usually about five minutes.

Check it from your own machine:

```bash
ping admin.example.com
```

If the reply shows your server's IP, you are ready. The installer checks this again so you cannot get it wrong quietly.

## Step 3. Connect to the server

From your own computer — Terminal on macOS and Linux, PowerShell on Windows:

```bash
ssh root@203.0.113.10
```

Use your own IP. The first connection asks whether you trust this server; answer `yes`. Then it asks for the root password.

> The password does not appear as you type it — no dots, no asterisks. That is normal. Type it blind and press <kbd>Enter</kbd>.

## Step 4. One package

Yulia's installer is written in Ruby, so Ruby is what it needs — nothing else:

```bash
apt-get update && apt-get install -y ruby curl
```

Everything else — Docker, the database, the web server — is installed by the installer itself.

## Step 5. The installer

```bash
curl -fsSL https://raw.githubusercontent.com/emostr/yulia/main/InstallYulia.rb -o InstallYulia.rb
sudo ruby InstallYulia.rb
```

A framed screen with a menu appears. Move with <kbd>↑</kbd> <kbd>↓</kbd>, choose with <kbd>Enter</kbd>, leave with <kbd>Ctrl</kbd>+<kbd>C</kbd>.

In order, the installer:

1. checks that there is enough memory and disk space;
2. asks for the admin panel's domain and **checks it against DNS** — if the record has not spread yet, it says so plainly and offers to check again;
3. asks for a Let's Encrypt address, used only to warn you if a certificate is ever about to expire;
4. installs Docker;
5. downloads Yulia;
6. generates the passwords and keys, so you do not have to invent any;
7. builds and starts everything;
8. waits until the application answers.

That takes five to ten minutes, almost all of it downloading.

> If it stops part way, simply run it again. The script is **idempotent**: it continues where it left off, and running it twice breaks nothing.

## Step 6. First sign-in

When the installer says it has finished, open this in a browser on **your own** computer:

```
https://admin.example.com
```

Continue with [first steps](/yulia/en/first-steps/): you will choose a password, enrol a second factor, and land in the admin panel.

**You never need to come back to the server** — not even for updates. See [Updating](/yulia/en/updating/).

## Trying it locally

You do not need a server just to look at it. On your own machine, if you have Docker:

```bash
git clone https://github.com/emostr/yulia.git
cd yulia
cp .env.example .env
# The key that signs cookies. The application will not start without it.
sed -i '' "s/^SECRET_KEY_BASE=$/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env
docker compose up -d --build
```

The admin panel opens at `http://localhost:8080`. There are no domains or certificates in this mode, so sites are viewed at `/preview/<site-address>`.
