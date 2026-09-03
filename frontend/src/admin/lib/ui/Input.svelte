<script lang="ts">
  interface Props {
    value: string;
    type?: string;
    placeholder?: string;
    autocomplete?: string;
    disabled?: boolean;
    required?: boolean;
    autofocus?: boolean;
    inputmode?: 'text' | 'numeric';
    oninput?: () => void;
  }

  let {
    value = $bindable(''),
    type = 'text',
    placeholder,
    autocomplete,
    disabled = false,
    required = false,
    autofocus = false,
    inputmode,
    oninput
  }: Props = $props();
</script>

<input
  {type}
  {placeholder}
  {autocomplete}
  {disabled}
  {required}
  {inputmode}
  bind:value
  {oninput}
  {autofocus}
  class="w-full h-10 px-3 bg-surface-2 border border-line text-ink text-sm
         focus:outline-none focus:border-accent transition-colors
         disabled:opacity-50 placeholder:text-faint"
/>
