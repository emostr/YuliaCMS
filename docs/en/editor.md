---
title: The visual editor
description: How a page is assembled — blocks, their order, their settings, drafts and publishing.
permalink: /en/editor/
---

A page in Yulia is a stack of blocks. A block is one finished thing: a hero, a paragraph of text, a gallery, a form. You stack them top to bottom and configure each one.

## The editor screen

On the left is the list of blocks; on the right, the settings for whichever block is selected. Along the top: the page's name, its state, and the buttons.

The list on the left shows not only the block type but the first line of its content, so it reads like the page itself rather than a list of "text, text, image".

## Blocks

### Adding

**Add** opens the list. Blocks are grouped: layout, text, pictures, interactive, and your own blocks separately.

A new block lands **after the selected one**, not at the end, because somebody pointing at a spot on the page expects it to appear there.

### Reordering

Drag a block by the handle on its left, or use the <kbd>↑</kbd> <kbd>↓</kbd> buttons on the block itself, which is steadier on a trackpad.

### Duplicating and removing

Hover over a block and the buttons appear on the right. Duplicating copies the block with all its settings, which is faster than configuring a similar one from scratch.

## The built-in blocks

| Block | What it is for |
|---|---|
| **Hero** | a large opening screen: heading, subheading, picture, button |
| **Heading** | a section heading; the level is chosen, and it is a real `h1`...`h4` |
| **Text** | paragraphs, lists, quotes, pictures, [formulas]({{ '/en/text/' | relative_url }}) |
| **Quote** | a testimonial with an attribution |
| **Image** | one picture with a caption |
| **Gallery** | several pictures in a grid |
| **Features** | cards in two to four columns |
| **Call to action** | a highlighted block with a button |
| **Button** | a standalone button with a link |
| **Form** | a contact form; replies land in Submissions |
| **Embed** | a map, video or player from another site |
| **Divider**, **Spacer** | air between sections |

Not enough? [Write your own block]({{ '/en/blocks/' | relative_url }}).

## Block settings

The panel on the right is assembled from the fields the block declares. Fields come in several kinds: a line of text, a longer passage, rich text, a choice from a list, a switch, a picture, a link, and lists — the pictures in a gallery, say, or the fields of a form.

In a list, each item can be moved, copied or removed.

## Pictures

In a picture field, press the icon on the right to open the media library. You can upload a new file there and it is placed in the block immediately.

Uploaded files live under **Files** and are available to every page of the site.

## Drafts and publishing

This separation is the editor's main safety net.

- **Save** (<kbd>Ctrl</kbd>+<kbd>S</kbd>) writes the draft. Visitors notice nothing.
- **Publish** moves the draft onto the live site.

Until you press Publish, visitors see the previously published version, so you can abandon a page half-finished without consequence.

The state is written in the header: "unsaved", "unpublished", "published".

## Preview

The eye button splits the screen: the editor on the left, the real page on the right. It refreshes when you save, so what you see is what a visitor gets.

## History

Every save snapshots the previous draft first. The last fifty are kept — a safety net against a bad edit, not an archive.

## Keyboard

| Keys | Action |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>S</kbd> | save the draft |
| <kbd>Esc</kbd> | close a dialog |
