---
title: Blocks in Svelte
description: When you need a real component in the browser — how it is compiled on the server and why it loads only where it is placed.
permalink: /en/svelte/
---

A block in [Liquid with htmx](/YuliaCMS/en/htmx/) covers nearly everything. Sometimes, though, you need logic **inside the browser** with no round trip to the server: a calculator, a configurator, an interactive diagram. That is what Svelte blocks are for.

> This is not the "more advanced" path, just a different one. If htmx solves the problem, use htmx: it will be faster and the visitor gets no JavaScript at all.

## How it works

A Svelte block becomes an **island**: the server renders an empty mount point on the page and loads that block's bundle beside it. The bundle brings its own spot to life and leaves the rest of the page alone.

The consequence is the important part: **a page without such a block loads nothing**. One island is one request. The rest of the site stays plain HTML.

## The component is compiled on your server

When you save the block, Yulia compiles it on your own server, where a compiler is installed for the purpose. There is nothing to wait for, nothing to install, and no server access required.

While the build runs, the block is marked "building" and cannot be placed on a page. If the compiler complains, the error is shown in the block's dialog exactly as the compiler produced it, so the line with the typo is visible.

## An example

**Blocks** → **Svelte**. Fields are declared as they are for a Liquid block, and arrive in the component as props.

With a `title` (text) field and a `start` (number) field:

```svelte
<script>
  // Field values arrive as props.
  let { title = 'Counter', start = 0 } = $props();

  // Svelte 5: reactive state is declared with the $state rune.
  let count = $state(Number(start) || 0);
</script>

<div class="y-features">
  <h2 class="y-features-title">{title}</h2>

  <button class="y-button y-button-solid" onclick={() => count++}>
    Pressed {count} times
  </button>
</div>
```

## What you need to know about Svelte 5

Yulia uses **Svelte 5**, where runes replaced the older syntax. If you are reading an article from a few years ago, check it against this:

| Svelte 3–4 | Svelte 5 |
|---|---|
| `export let title` | `let { title } = $props()` |
| `let count = 0` (reactive by itself) | `let count = $state(0)` |
| `$: doubled = count * 2` | `let doubled = $derived(count * 2)` |
| `on:click={...}` | `onclick={...}` |
| `$: { ... }` for a side effect | `$effect(() => { ... })` |

## Styling

The site's classes (`y-button`, `y-features`, `y-cols-3`) are available inside an island, because the site's stylesheet is loaded on the page. Use them and your block will not look like a foreign object.

A `<style>` block inside the component works too; Svelte scopes it to that component.

## What an island cannot do

- **Wrap the page.** An island lives in its own place in the stack of blocks, between its neighbours.
- **Render on the server.** Until the bundle loads, the island's spot is empty. Do not put text there that needs to be found by search engines — ordinary blocks exist for text.
- **Reach the database.** The component runs in the visitor's browser. It can only ask the server for data, like any other script.

## Which to choose

| Task | Use |
|---|---|
| Contact form | the built-in Form block |
| Load more entries | htmx, `hx-swap="beforeend"` |
| Search as you type | htmx, `hx-trigger="input changed delay:500ms"` |
| Tabs, accordion | htmx, or plain HTML (`<details>`) |
| Calculator, configurator | Svelte |
| Interactive diagram, editor | Svelte |

## Size

Each island is self-contained: it carries what it needs and weighs roughly 30–40 KB. Two different islands on one page means two bundles.

That is a deliberate trade. A self-contained bundle is simpler and more robust than a shared library, and only the pages that actually place an island pay for it.
