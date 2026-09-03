<script lang="ts">
  interface Option {
    value: string;
    label: string;
  }

  interface Props {
    value: string;
    options: Option[];
    disabled?: boolean;
  }

  let { value = $bindable(''), options, disabled = false }: Props = $props();
</script>

<select
  bind:value
  {disabled}
  class="w-full h-10 px-3 bg-surface-2 border border-line text-ink text-sm cursor-pointer
         focus:outline-none focus:border-accent transition-colors disabled:opacity-50"
>
  {#each options as option (option.value)}
    <option value={option.value}>{option.label}</option>
  {/each}
</select>
