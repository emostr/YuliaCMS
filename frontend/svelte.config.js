import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

export default {
  // Lets components use lang="ts" and modern CSS in <style> blocks.
  preprocess: vitePreprocess()
};
