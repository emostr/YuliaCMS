---
title: Domains and HTTPS
description: How to attach a domain to a site, and why the certificate appears by itself.
permalink: /en/domains/
---

The site is ready; now give it an address. This is done entirely from the admin panel — there is no need to return to the server.

## Step 1. DNS

At your domain registrar, find **DNS records** and add:

| Field | Value |
|---|---|
| Type | `A` |
| Name | `@` for `example.com`, or `www` for `www.example.com` |
| Value | your server's IP address |

The server's IP is the one you used during installation, and it is shown in your hosting provider's panel.

The record spreads across the internet in anywhere from a minute to a few hours. Usually about five minutes.

## Step 2. The domain in the admin panel

Site → **Domains** → type the domain → **Add**.

Yulia checks DNS immediately and tells you what it sees:

- **DNS is correct** — nothing further to do.
- **The domain has no A record** — it has not appeared yet, or was not saved. Wait and add the domain again.
- **The domain points somewhere else** — the record exists but leads elsewhere. You are shown where it points and where it should.

## Step 3. There is no certificate to wait for

The Let's Encrypt certificate is issued **on the first request** to the domain. Open the address in a browser: that first load takes a few seconds longer than usual, and that is the certificate being issued. Afterwards the domain is marked "certificate issued" in the admin panel.

Renewal happens on its own, a month before expiry. There is never anything to do about it.

## The primary domain

When a site has several domains (`example.com` and `www.example.com`), one of them is primary. It:

- appears in the `canonical` link, which tells search engines which address is the real one;
- is shown in the admin panel as the site's address.

The first domain added becomes primary automatically. Change it with "Make primary".

## Several sites

Each site has its own domains. One server comfortably hosts a dozen sites on different domains: Yulia looks at the address the visitor arrived on and serves the right site.

## The admin panel's domain

It is set during installation and is kept separate from the sites. To change it, run the installer again with a different domain — and remember the DNS record for the new one.

## Why somebody else's domain cannot be pointed here

Caddy, which issues the certificates, asks Yulia for permission for every unfamiliar name. Permission is granted only for domains that have been added in the admin panel.

Without that check, anyone could aim a domain at your server and exhaust your Let's Encrypt rate limit, after which your own certificates would stop being issued.

## When a site will not open

**"This site can't be reached".** DNS has not spread yet, or the record is wrong. Check: `ping example.com` should show the server's IP.

**A security warning.** The certificate has not been issued yet. Check that the domain is added in the admin panel and that DNS points here, then reload after a minute.

**The wrong site opens.** The domain is attached to another site in the same installation. Check the Domains section of both.

**The admin panel opens.** The domain is not listed on any site, so Yulia does not know what to show and serves the panel instead.
