<script lang="ts">
  import AuthFrame from './AuthFrame.svelte';
  import { Button, Field, Input, Notice } from '../lib/ui';
  import { session } from '../lib/session.svelte';
  import { errorMessage } from '../lib/api';

  let name = $state('');
  let email = $state('');
  let password = $state('');
  let confirmation = $state('');
  let busy = $state(false);
  let error = $state('');

  // The server enforces this too; saying it here means the user learns about it
  // before typing a password twice rather than after.
  const tooShort = $derived(password.length > 0 && password.length < 12);
  const mismatch = $derived(confirmation.length > 0 && password !== confirmation);
  const ready = $derived(
    name.trim() !== '' && email.trim() !== '' && password.length >= 12 && password === confirmation
  );

  async function submit(event: Event): Promise<void> {
    event.preventDefault();
    if (!ready || busy) return;

    busy = true;
    error = '';
    try {
      await session.completeSetup({
        name,
        email,
        password,
        password_confirmation: confirmation
      });
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }
</script>

<AuthFrame
  step="Шаг 1 из 2"
  title="Создайте владельца"
  subtitle="Это первая и единственная учётная запись, которую вы заводите вручную. Дальше всё делается из админки."
>
  <form onsubmit={submit}>
    {#if error}
      <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
    {/if}

    <Field label="Как вас зовут">
      <Input bind:value={name} autocomplete="name" autofocus required />
    </Field>

    <Field label="Почта" hint="Ею вы будете входить.">
      <Input bind:value={email} type="email" autocomplete="username" required />
    </Field>

    <Field
      label="Пароль"
      hint="Не короче 12 символов."
      error={tooShort ? 'Пока слишком короткий.' : ''}
    >
      <Input bind:value={password} type="password" autocomplete="new-password" required />
    </Field>

    <Field label="Пароль ещё раз" error={mismatch ? 'Пароли не совпадают.' : ''}>
      <Input bind:value={confirmation} type="password" autocomplete="new-password" required />
    </Field>

    <Button type="submit" icon="check" disabled={!ready} {busy}>Создать и продолжить</Button>
  </form>
</AuthFrame>
