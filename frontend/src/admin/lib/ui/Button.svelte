<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  interface Props {
    variant?: 'solid' | 'outline' | 'ghost' | 'danger';
    size?: 'sm' | 'md';
    icon?: string;
    type?: 'button' | 'submit';
    disabled?: boolean;
    busy?: boolean;
    title?: string;
    onclick?: (event: MouseEvent) => void;
    children?: Snippet;
  }

  let {
    variant = 'solid',
    size = 'md',
    icon,
    type = 'button',
    disabled = false,
    busy = false,
    title,
    onclick,
    children
  }: Props = $props();

  const variants: Record<string, string> = {
    solid: 'bg-accent text-on-accent hover:brightness-110',
    outline: 'border border-line-strong text-ink hover:border-accent hover:text-accent',
    ghost: 'text-muted hover:text-ink hover:bg-surface-3',
    danger: 'bg-danger text-white hover:brightness-110'
  };

  const sizes: Record<string, string> = {
    sm: 'h-8 px-3 text-xs',
    md: 'h-10 px-4 text-sm'
  };
</script>

<button
  {type}
  {title}
  disabled={disabled || busy}
  {onclick}
  class="inline-flex items-center justify-center gap-2 font-bold transition-all cursor-pointer
         disabled:opacity-40 disabled:cursor-not-allowed {variants[variant]} {sizes[size]}"
>
  {#if busy}
    <Icon name="refresh" size={size === 'sm' ? 13 : 15} class="animate-spin" />
  {:else if icon}
    <Icon name={icon} size={size === 'sm' ? 13 : 15} />
  {/if}
  {@render children?.()}
</button>
