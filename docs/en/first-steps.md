---
title: First steps
description: The first sign-in, the mandatory second factor, and your first site.
permalink: /en/first-steps/
---

The installer has finished and told you the admin panel's address. Open it in a browser on your own computer — everything from here happens there.

## The owner account

The first screen asks you to create an account. There is only ever one of these: as soon as an owner exists, this page closes for good, so a server left unattended for a day cannot be claimed by a passer-by.

The password must be **at least 12 characters**. That is not fussiness: every site on this server is published through this panel.

## The second factor is mandatory

Straight after the password, Yulia shows a QR code and asks you to enrol an authenticator app. This step cannot be skipped.

Any app will do: Google Authenticator, Aegis, 1Password, Bitwarden, or the one built into iOS. Scan the code, type in the six digits it shows, and the protection is on.

> You have to enter a code **before** protection is switched on. Yulia will not take your word for it: otherwise a misconfigured app would lock you out of your own server.

### Recovery codes

Ten codes appear immediately afterwards. Each works once, and they are what you use if the phone is ever lost.

**Save them now.** They are never shown again: the server stores only their fingerprints. Print them, or put them in a password manager.

A fresh set can be issued at any time from **Account**. Doing so stops the old ones working.

## Your first site

The admin panel opens on a list of sites, which is empty. Press **New site** and give it a name. It arrives with a home page and a hero block already on it, so the editor does not greet you with nothing.

Next: [the visual editor](/yulia/en/editor/).

## Viewing a site before it has a domain

Until a domain is attached, a site is reachable at an internal address:

```
https://admin.example.com/preview/site-address
```

The site's address is shown in its settings. Drafts are visible here too — but **only to you**, while signed in. A visitor who is not signed in gets a 404.

When the site is ready, [attach a domain](/yulia/en/domains/).

## What lives where

| Section | What it is for |
|---|---|
| **Pages** | everything on the site |
| **Blocks** | your own blocks, when the built-in ones are not enough |
| **Files** | pictures you place in blocks |
| **Domains** | the site's addresses and certificates |
| **Submissions** | what visitors sent through a form |
| **Settings** | name, appearance, the menu in the header |
