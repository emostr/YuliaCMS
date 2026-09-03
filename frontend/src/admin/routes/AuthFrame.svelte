<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    title: string;
    subtitle?: string;
    step?: string;
    children: Snippet;
  }

  let { title, subtitle, step, children }: Props = $props();
</script>

<div class="min-h-screen flex items-center justify-center p-4 sm:p-6">
  <div class="w-full max-w-md">
    <div class="mb-6 text-center">
      <div class="text-3xl font-black tracking-tighter text-accent">Yulia</div>
      {#if step}
        <div class="ng-label text-faint mt-1">{step}</div>
      {/if}
    </div>

    <div class="bg-surface border border-line border-l-[3px] border-l-accent p-6 sm:p-8 ng-enter">
      <h1 class="font-bold text-xl tracking-tight mb-1">{title}</h1>
      {#if subtitle}
        <p class="text-sm text-muted mb-6">{subtitle}</p>
      {:else}
        <div class="mb-6"></div>
      {/if}

      {@render children()}
    </div>
  </div>
</div>
