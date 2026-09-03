<script lang="ts">
  interface Props {
    checked: boolean;
    label?: string;
    disabled?: boolean;
  }

  let { checked = $bindable(false), label, disabled = false }: Props = $props();
</script>

<label class="inline-flex items-center gap-2.5 cursor-pointer select-none {disabled ? 'opacity-50' : ''}">
  <input type="checkbox" bind:checked {disabled} class="sr-only peer" />
  <span
    class="relative w-9 h-5 bg-surface-3 border border-line transition-colors
           peer-checked:bg-accent peer-checked:border-accent
           peer-focus-visible:outline peer-focus-visible:outline-2 peer-focus-visible:outline-accent
           peer-focus-visible:outline-offset-2"
  >
    <span
      class="absolute top-0.5 left-0.5 w-3.5 h-3.5 bg-ink transition-transform
             peer-checked:translate-x-4 {checked ? 'translate-x-4 bg-on-accent' : ''}"
    ></span>
  </span>
  {#if label}
    <span class="text-sm">{label}</span>
  {/if}
</label>
