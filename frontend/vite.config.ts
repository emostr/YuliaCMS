import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import tailwindcss from '@tailwindcss/vite';

// Builds the admin panel: a Svelte single-page application.
//
// The output lands in frontend/dist and is copied into the Rails public directory
// by scripts/install-assets.mjs. Building into dist first keeps the Docker build
// self-contained: the image copies one directory instead of reaching outside the
// build context.
export default defineConfig({
  plugins: [svelte(), tailwindcss()],
  root: 'src/admin',
  base: '/admin/',
  build: {
    outDir: '../../dist/admin',
    emptyOutDir: true,
    // The admin is behind a login; a source map there costs nothing and makes
    // a bug report from a real installation actionable.
    sourcemap: true
  },
  server: {
    port: 5173,
    proxy: {
      // In development the panel runs on Vite and talks to Rails next door.
      '/api': 'http://127.0.0.1:3111',
      '/_yulia': 'http://127.0.0.1:3111'
    }
  }
});
