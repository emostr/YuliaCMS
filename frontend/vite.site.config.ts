import { defineConfig } from 'vite';

// Builds what a published site loads: htmx, the island bootstrapper, and the
// stylesheet.
//
// This is deliberately separate from the admin build. A visitor to somebody's
// site must never download the editor, and keeping the two builds apart is the
// simplest way to guarantee that.
export default defineConfig({
  // site.css is written by hand rather than compiled: the public stylesheet is
  // plain CSS with custom properties, and running it through a bundler would
  // buy nothing. Vite copies this directory across verbatim.
  publicDir: "src/site/public",

  build: {
    outDir: 'dist/yulia',
    emptyOutDir: true,
    // Fixed filenames, because the public layout references them directly and
    // a content hash would mean regenerating templates on every build.
    rollupOptions: {
      input: {
        'htmx.min': 'src/site/htmx.ts',
        islands: 'src/site/islands.ts'
      },
      output: {
        entryFileNames: '[name].js',
        assetFileNames: '[name][extname]'
      }
    },
    cssCodeSplit: false,
    sourcemap: false
  }
});
