<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  interface Props {
    icon?: string;
    title: string;
    text?: string;
    children?: Snippet;
  }

  let { icon = 'layers', title, text, children }: Props = $props();
</script>

<div class="flex flex-col items-center justify-center text-center py-16 px-6">
  <div class="text-faint mb-4"><Icon name={icon} size={32} /></div>
  <h3 class="font-bold text-base mb-1">{title}</h3>
  {#if text}
    <p class="text-sm text-muted max-w-sm mb-5">{text}</p>
  {/if}
  {@render children?.()}
</div>
