<script lang="ts">
  import { icons } from './icons';

  interface Props {
    name: string;
    size?: number;
    class?: string;
  }

  let { name, size = 16, class: className = '' }: Props = $props();

  // An unknown name renders nothing rather than a broken glyph.
  const path = $derived(icons[name] ?? '');
</script>

{#if path}
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    class={className}
    aria-hidden="true"
  >
    <path d={path} />
  </svg>
{/if}
