<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    label?: string;
    hint?: string;
    error?: string;
    children: Snippet;
  }

  let { label, hint, error, children }: Props = $props();
</script>

<label class="block mb-4">
  {#if label}
    <span class="ng-label text-muted block mb-1.5">{label}</span>
  {/if}

  {@render children()}

  {#if error}
    <span class="block mt-1 text-xs text-danger">{error}</span>
  {:else if hint}
    <span class="block mt-1 text-xs text-faint">{hint}</span>
  {/if}
</label>
