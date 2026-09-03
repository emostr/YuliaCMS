---
title: "htmx: interactivity without JavaScript"
description: How to build a block that talks to the server without writing a line of JavaScript. A guide to htmx 4 inside Yulia.
permalink: /en/htmx/
---

This is the recommended way to add interaction to a site. Read it end to end: htmx is simpler than it first looks, and by the end of this page you will be writing blocks that update without reloading the page, knowing no JavaScript at all.

## The idea, in one paragraph

A "live" page normally works like this: the browser asks the server for data, receives JSON, and JavaScript you wrote turns that JSON into HTML. htmx removes the middle step. The browser asks the server for **finished HTML** and puts it where you said. There is nothing to write — an attribute says where to go and where to put the answer.

```html
<button hx-get="/api/time" hx-target="#clock">What time is it?</button>
<div id="clock"></div>
```

Press the button, htmx fetches `/api/time`, gets HTML back and puts it inside `#clock`. That is the whole mechanism.

> Yulia uses **htmx 4**. It differs noticeably from htmx 2, which most examples on the internet are written against. The differences are listed [at the end of this page](#how-htmx-4-differs-from-htmx-2).

## htmx loads itself

You do not add anything to your markup. Yulia looks at the blocks on a page and loads htmx **only if something needs it**: a built-in Form block, or one of your own blocks whose template contains an `hx-` attribute.

A page of headings, text and pictures loads no JavaScript at all. That is not a later optimisation — it is how it always works.

## Five attributes are enough

### Where to go

| Attribute | What it does |
|---|---|
| `hx-get="/path"` | GET request |
| `hx-post="/path"` | POST request |
| `hx-put`, `hx-patch`, `hx-delete` | the other methods |

### When

By default: buttons and links fire on click, inputs on change, forms on submit. Change it with `hx-trigger`:

```html
<!-- on hover -->
<div hx-get="/tooltip" hx-trigger="mouseenter">Hover me</div>

<!-- 500 ms after the person stops typing -->
<input name="q" hx-get="/search" hx-trigger="input changed delay:500ms" hx-target="#results">

<!-- when the element is scrolled into view -->
<div hx-get="/more" hx-trigger="revealed">Loading...</div>

<!-- every ten seconds -->
<div hx-get="/status" hx-trigger="every 10s"></div>
```

Useful modifiers: `once` fires a single time, `delay:<time>` waits, `throttle:<time>` limits the rate, `from:<selector>` listens on another element.

### Where the answer goes

```html
<button hx-get="/price" hx-target="#total">Recalculate</button>
```

Without `hx-target`, the answer goes into the element itself. Besides ordinary CSS selectors you can use:

- `this` — the element itself;
- `closest .card` — the nearest matching ancestor;
- `find .price` — the first matching descendant;
- `next`, `previous` — siblings.

### How it goes in

| `hx-swap` value | What happens |
|---|---|
| `innerHTML` | replace the contents (default) |
| `outerHTML` | replace the element itself |
| `beforeend` | append — this is how "load more" works |
| `afterbegin` | insert at the start |
| `delete` | remove the element |
| `none` | change nothing |
| `outerMorph` | update carefully, preserving state — typed text, cursor position, open menus |

`outerMorph` is built into htmx 4: the separate morphing library that used to be required is no longer needed.

### What to show while the request is in flight

```html
<button hx-post="/save" hx-disable="this">Save</button>
```

`hx-disable` switches the element off for the duration, so the button cannot be pressed twice. Separately, htmx adds an `htmx-request` class during a request; Yulia's stylesheet already styles it and dims the button.

## Inheritance: the big change in htmx 4

In htmx 2, attributes were inherited by descendants automatically. In htmx 4 they are inherited **only when you ask**. This is the trap everyone following older examples falls into.

```html
<!-- Does NOT work in htmx 4: the buttons never see hx-target -->
<div hx-target="#output">
  <button hx-get="/one">One</button>
  <button hx-get="/two">Two</button>
</div>

<!-- This does -->
<div hx-target:inherited="#output">
  <button hx-get="/one">One</button>
  <button hx-get="/two">Two</button>
</div>
```

The `:inherited` modifier says "this attribute is for my descendants". It goes on the parent, not on the children.

## What this looks like in a Yulia block

Your block is a [Liquid](/yulia/en/blocks/) template, and field values arrive as `block.<key>`. Here is a "load more" block:

```liquid
{% raw %}<section class="y-features">
  <h2>{{ block.title | escape }}</h2>

  <div id="list-{{ block.id }}">
    {% comment %} The first batch arrives with the page. {% endcomment %}
  </div>

  <button class="y-button y-button-outline"
          hx-get="/news?page=2"
          hx-target="#list-{{ block.id }}"
          hx-swap="beforeend"
          hx-disable="this">
    {{ block.button_label | escape }}
  </button>
</section>{% endraw %}
```

Note `{% raw %}{{ block.id }}{% endraw %}` inside the identifier: if the block is placed on a page twice, the ids will not collide.

## The built-in Form block is a worked example

Yulia's Form block is built entirely on htmx, and its template is short enough to read:

```html
<form hx-post="/_yulia/forms/BLOCK-ID"
      hx-target="this"
      hx-swap="outerHTML"
      hx-disable="find button[type=submit]">
  ...
  <button type="submit">Send</button>
</form>
```

Three attributes give the whole behaviour: the form posts itself, the reply — a "thank you" message — **replaces the form**, and the submit button is disabled while the request is in flight.

Notice also that the form carries an ordinary `method="post"` and `action`. If htmx fails to load, or JavaScript is switched off, the browser submits the form the old way and gets a full page back. The block degrades instead of breaking.

## Headers the server sees

Your server can tell an htmx request from an ordinary visit:

| Header | Meaning |
|---|---|
| `HX-Request` | always `true` on htmx requests |
| `HX-Source` | what triggered it, as `button#save` |
| `HX-Target` | where the answer will go, as `div#results` |
| `HX-Current-URL` | the address the visitor is on |

And the server's answer can direct what happens next:

| Header | What it does |
|---|---|
| `HX-Trigger` | fire an event on the page |
| `HX-Redirect` | send the visitor elsewhere |
| `HX-Retarget` | put the answer somewhere else |
| `HX-Reswap` | put it in differently |
| `HX-Push-Url` | add an address to browser history |

## Updating several regions in one answer

This used to need `hx-swap-oob`. htmx 4 has a clearer way — the `<hx-partial>` tag. The server answers with several pieces, each naming its own destination:

```html
<hx-partial hx-target="#cart" hx-swap="innerHTML">
  3 items
</hx-partial>

<hx-partial hx-target="#messages" hx-swap="beforeend">
  <div>Added to cart</div>
</hx-partial>
```

## Common mistakes

**The answer arrives but nothing changes.** Most likely `hx-target` points at an element that does not exist. The selector is resolved when the request happens, not when the page loads.

**It worked in an example online but not here.** Almost certainly an htmx 2 example. Check inheritance (`:inherited`) and event names (`htmx:after:swap`, not `htmx:afterSwap`).

**The server returned an error and it was swapped into the page.** In htmx 4 every response is swapped except 204 and 304. If you do not want that:

```html
<div hx-get="/data" hx-status:5xx="swap:none"></div>
```

**People press the button twice.** Add `hx-disable="this"`.

## How htmx 4 differs from htmx 2

If you are reading an older article or example, check it against this table.

| htmx 2 | htmx 4 |
|---|---|
| attributes inherited automatically | needs the `:inherited` modifier |
| `htmx:afterSwap` | `htmx:after:swap` (colons, not camelCase) |
| `hx-ext="name"` | not needed: loading the extension enables it |
| `hx-disabled-elt` | `hx-disable` |
| `hx-disable` (switch htmx off) | `hx-ignore` |
| `hx-vars` | `hx-vals='js:...'` |
| `hx-swap-oob` | prefer `<hx-partial>` |
| `HX-Trigger` request header | `HX-Source`, formatted as `tag#id` |
| 4xx and 5xx were not swapped | everything swaps except 204 and 304 |
| separate library for morphing | built in: `outerMorph`, `innerMorph` |

## Where to go next

- [Your own blocks](/yulia/en/blocks/) — how a block template is put together and what fields exist.
- [Blocks in Svelte](/yulia/en/svelte/) — for when htmx is not enough.
- [The official htmx documentation](https://htmx.org) — if you want to go deeper.
