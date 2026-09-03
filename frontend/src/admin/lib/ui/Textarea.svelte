<script lang="ts">
  interface Props {
    value: string;
    rows?: number;
    placeholder?: string;
    mono?: boolean;
    disabled?: boolean;
  }

  let { value = $bindable(''), rows = 4, placeholder, mono = false, disabled = false }: Props =
    $props();
</script>

<textarea
  {rows}
  {placeholder}
  {disabled}
  bind:value
  class="w-full px-3 py-2 bg-surface-2 border border-line text-ink text-sm resize-y
         focus:outline-none focus:border-accent transition-colors placeholder:text-faint
         {mono ? 'font-mono text-xs leading-relaxed' : ''}"
></textarea>
