---
title: Your own blocks
description: How to write a block in Liquid, what fields are available, and why it is not ERB.
permalink: /en/blocks/
---

The built-in blocks are enough for most sites. When they are not — a timetable, a calculator, a product card — you can write your own, from the admin panel, without touching the server.

There are two kinds:

- **HTML** — a template the server renders. The recommended path: fast, works without JavaScript, and [pairs with htmx](/yulia/en/htmx/).
- **[Svelte](/yulia/en/svelte/)** — a real component, for when you need substantial logic in the browser.

This page is about the first.

## Where

**Blocks** → **HTML + htmx**. A dialog opens with the block's description and fields on the left, and its template on the right.

## Templates are written in Liquid

Not ERB, and not Ruby. [Liquid](https://shopify.github.io/liquid/) is a template language designed for exactly this situation: written by a user, executed on somebody else's server.

The reason is straightforward. One Yulia installation hosts several sites. If a block could execute Ruby, an editor on one site would have complete access to the server and to every other site on it. Liquid cannot do that, and will not learn to.

In practice the restriction barely gets in the way: Liquid does values, conditions, loops and filters, and a block rarely needs more.

## What a template can see

| Variable | What it holds |
|---|---|
| `block.<field key>` | the value typed into the editor |
| `block.id` | this block's unique id on the page |
| `site.name`, `site.url`, `site.locale` | about the site |
| `page.title`, `page.path` | about the page |
| `form.action`, `form.csrf_token` | for forms |

## Always escape

```liquid
{% raw %}{{ block.title | escape }}{% endraw %}
```

The `escape` filter turns `<` and `>` into harmless text. Without it, a visitor who gets somebody else's script onto the page gets it executed — and you get a compromised site.

There is one exception: a field of type rich text. Yulia has already cleaned that on the server, and it is output without `escape`; escaping it would show the reader tags instead of formatting.

## Fields

A field is what the editor shows in the panel on the right. Each has a key (in Latin letters, used in the template), a label and a type.

| Type | What it shows |
|---|---|
| `text` | a single line |
| `textarea` | a longer passage |
| `richtext` | the full formatting editor |
| `number` | a number |
| `boolean` | a switch |
| `select` | a choice from a list |
| `image` | a picker from the media library |
| `link` | a link |
| `color` | a colour |

## A complete example

An "opening hours" block: a heading and a note.

**Fields:** `title` (text), `note` (textarea).

**Template:**

```liquid
{% raw %}{% comment %}
  Opening hours. `note` may run to several lines, and newline_to_br turns the
  breaks into <br>; without it they would collapse into spaces.
{% endcomment %}
<section class="y-features">
  <h2 class="y-features-title">{{ block.title | escape }}</h2>

  {% if block.note != blank %}
    <p>{{ block.note | escape | newline_to_br }}</p>
  {% endif %}
</section>{% endraw %}
```

## Styling classes

Use the classes that ship with Yulia and your block will look like part of the site, picking up its theme and accent colour:

| Class | What it is |
|---|---|
| `y-features` | a section with spacing |
| `y-features-title` | a section heading |
| `y-feature` | a card |
| `y-button y-button-solid` | a filled button |
| `y-button y-button-outline` | an outlined button |
| `y-figure` | a picture with a caption |
| `y-cols-2`, `y-cols-3`, `y-cols-4` | a column grid |
| `y-align-center` | centred |

Colours are available as CSS variables: `var(--ng-accent)`, `var(--ng-ink)`, `var(--ng-muted)`, `var(--ng-line)`, `var(--ng-surface)`.

## Reading how the built-in blocks are written

Every Yulia block is written in the same Liquid and lives in the repository under [`backend/app/blocks`](https://github.com/emostr/yulia/tree/main/backend/app/blocks). That is not hidden code — it is a set of worked examples to read and copy.

## When a block is broken

A template with an error does not take the page down: the broken block simply is not drawn and the others stay where they are. One typo does not cost a visitor the whole page.

## Next

- [htmx](/yulia/en/htmx/) — teaching a block to talk to the server.
- [Blocks in Svelte](/yulia/en/svelte/) — when you need logic in the browser.
