<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  interface Props {
    tone?: 'info' | 'success' | 'warning' | 'danger';
    children: Snippet;
  }

  let { tone = 'info', children }: Props = $props();

  const tones: Record<string, { border: string; icon: string; text: string }> = {
    info: { border: 'border-l-info', icon: 'globe', text: 'text-info' },
    success: { border: 'border-l-success', icon: 'check', text: 'text-success' },
    warning: { border: 'border-l-warning', icon: 'warning', text: 'text-warning' },
    danger: { border: 'border-l-danger', icon: 'warning', text: 'text-danger' }
  };
</script>

<div class="flex items-start gap-3 p-4 bg-surface-2 border border-line border-l-[3px] {tones[tone].border}">
  <span class="{tones[tone].text} shrink-0 mt-0.5">
    <Icon name={tones[tone].icon} size={16} />
  </span>
  <div class="text-sm min-w-0">{@render children()}</div>
</div>
