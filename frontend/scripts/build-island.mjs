// Compiles one user-written Svelte block into a bundle a published page can load.
//
// Run by CompileIslandJob on the server, because Yulia promises that writing a
// block in the admin panel is enough - nobody should have to open a terminal to
// see their own block appear.
//
//   node scripts/build-island.mjs --input /tmp/x.svelte --outdir /path --name my-block
//
// The result registers itself with the island bootstrapper (src/site/islands.ts)
// rather than mounting on its own, so a page decides where and whether to mount.

import { build } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import { writeFile, mkdir, rm } from 'node:fs/promises';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { randomUUID } from 'node:crypto';

const here = dirname(fileURLToPath(import.meta.url));

function argument(flag) {
  const index = process.argv.indexOf(flag);
  return index === -1 ? null : process.argv[index + 1];
}

const input = argument('--input');
const outdir = argument('--outdir');
const name = argument('--name');

if (!input || !outdir || !name) {
  console.error('usage: build-island.mjs --input FILE --outdir DIR --name KEY');
  process.exit(1);
}

// A block key reaches this script from the database. It is validated on the way
// in, but a path separator here would write outside the islands directory, so
// it is checked again rather than trusted twice.
if (!/^[a-z][a-z0-9-]*$/.test(name)) {
  console.error(`refusing to build: "${name}" is not a valid block key`);
  process.exit(1);
}

const work = join(tmpdir(), `yulia-island-${randomUUID()}`);
await mkdir(work, { recursive: true });

// The entry point wraps the author's component: it mounts on request and hands
// the props the server rendered into the page.
const entry = join(work, 'entry.js');
await writeFile(
  entry,
  `
import { mount, unmount } from 'svelte';
import Component from ${JSON.stringify(resolve(input))};

const key = ${JSON.stringify(name)};

function attach(target, props) {
  // Anything already inside is placeholder markup from the server.
  target.innerHTML = '';
  const instance = mount(Component, { target, props });
  // Content swapped away by htmx should not leave a live component behind.
  target.__yuliaDestroy = () => unmount(instance);
}

if (window.yuliaIsland) {
  window.yuliaIsland(key, attach);
} else {
  // The bootstrapper has not run yet; queue until it does.
  (window.__yuliaPendingIslands ||= []).push([key, attach]);
}
`,
  'utf8'
);

try {
  await build({
    configFile: false,
    root: here,
    logLevel: 'warn',
    plugins: [svelte({ configFile: false, emitCss: false })],
    build: {
      outDir: outdir,
      emptyOutDir: false,
      // One self-contained file: a published page loads exactly one request per
      // island, with no shared chunk to coordinate.
      lib: { entry, formats: ['es'], fileName: () => `${name}.js` },
      minify: true,
      sourcemap: false,
      cssCodeSplit: false
    }
  });

  console.log(`built island ${name}`);
} finally {
  await rm(work, { recursive: true, force: true });
}
