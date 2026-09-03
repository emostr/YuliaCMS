<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  interface Props {
    open: boolean;
    title: string;
    subtitle?: string;
    size?: 'md' | 'lg' | 'xl';
    onclose: () => void;
    footer?: Snippet;
    children: Snippet;
  }

  let { open = $bindable(false), title, subtitle, size = 'md', onclose, footer, children }: Props =
    $props();

  const widths: Record<string, string> = {
    md: 'max-w-md',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl'
  };

  // Escape closes the dialog. Without it a keyboard user has to hunt for the
  // close button, which on a wide dialog can be a long way from the focus.
  function onkeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') onclose();
  }
</script>

<svelte:window {onkeydown} />

{#if open}
  <div
    class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/60 p-4 sm:p-8"
    role="presentation"
    onclick={(event) => {
      // Only a click on the backdrop itself closes; one that started inside the
      // dialog and drifted out should not.
      if (event.target === event.currentTarget) onclose();
    }}
  >
    <div
      class="w-full {widths[size]} bg-surface border border-line border-l-[3px] border-l-accent
             shadow-2xl ng-enter"
      role="dialog"
      aria-modal="true"
      aria-label={title}
    >
      <header class="flex items-start justify-between gap-4 px-5 py-4 border-b border-line">
        <div>
          <h2 class="font-bold text-base tracking-tight">{title}</h2>
          {#if subtitle}
            <p class="text-xs text-muted mt-0.5">{subtitle}</p>
          {/if}
        </div>
        <button
          type="button"
          onclick={onclose}
          class="text-muted hover:text-danger transition-colors cursor-pointer"
          aria-label="Закрыть"
        >
          <Icon name="x" size={18} />
        </button>
      </header>

      <div class="p-5">{@render children()}</div>

      {#if footer}
        <footer class="flex items-center justify-end gap-2 px-5 py-4 border-t border-line">
          {@render footer()}
        </footer>
      {/if}
    </div>
  </div>
{/if}
