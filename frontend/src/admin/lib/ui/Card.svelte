<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    title?: string;
    subtitle?: string;
    accent?: boolean;
    actions?: Snippet;
    children: Snippet;
  }

  let { title, subtitle, accent = false, actions, children }: Props = $props();
</script>

<section
  class="bg-surface border border-line {accent ? 'border-l-[3px] border-l-accent' : ''} ng-enter"
>
  {#if title || actions}
    <header class="flex items-start justify-between gap-4 px-5 py-4 border-b border-line">
      <div class="min-w-0">
        {#if title}
          <h2 class="font-bold text-base tracking-tight truncate">{title}</h2>
        {/if}
        {#if subtitle}
          <p class="text-xs text-muted mt-0.5">{subtitle}</p>
        {/if}
      </div>
      {#if actions}
        <div class="flex items-center gap-2 shrink-0">{@render actions()}</div>
      {/if}
    </header>
  {/if}

  <div class="p-5">{@render children()}</div>
</section>
