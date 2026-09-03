<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    tone?: 'neutral' | 'accent' | 'success' | 'warning' | 'danger';
    children: Snippet;
  }

  let { tone = 'neutral', children }: Props = $props();

  const tones: Record<string, string> = {
    neutral: 'border-line-strong text-muted',
    accent: 'border-accent text-accent',
    success: 'border-success text-success',
    warning: 'border-warning text-warning',
    danger: 'border-danger text-danger'
  };
</script>

<span class="inline-flex items-center px-2 py-0.5 border text-[11px] font-bold {tones[tone]}">
  {@render children()}
</span>
