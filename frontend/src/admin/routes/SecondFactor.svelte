<script lang="ts">
  import AuthFrame from './AuthFrame.svelte';
  import { Button, Field, Input, Notice } from '../lib/ui';
  import { session } from '../lib/session.svelte';
  import { errorMessage } from '../lib/api';

  let code = $state('');
  let busy = $state(false);
  let error = $state('');

  const hasRecovery = $derived(session.methods.includes('recovery'));

  async function submit(event: Event): Promise<void> {
    event.preventDefault();
    if (busy || code.trim() === '') return;

    busy = true;
    error = '';
    try {
      await session.submitSecondFactor(code.trim());
    } catch (e) {
      error = errorMessage(e);
      code = '';
    } finally {
      busy = false;
    }
  }
</script>

<AuthFrame
  step="Шаг 2 из 2"
  title="Код подтверждения"
  subtitle="Откройте приложение-аутентификатор и введите шестизначный код."
>
  <form onsubmit={submit}>
    {#if error}
      <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
    {/if}

    <Field
      label="Код"
      hint={hasRecovery ? 'Потеряли телефон? Введите сюда код восстановления.' : ''}
    >
      <Input
        bind:value={code}
        inputmode="numeric"
        autocomplete="one-time-code"
        placeholder="000000"
        autofocus
        required
      />
    </Field>

    <Button type="submit" icon="check" {busy}>Подтвердить</Button>
  </form>
</AuthFrame>
