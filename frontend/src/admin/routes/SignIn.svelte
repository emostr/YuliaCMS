<script lang="ts">
  import AuthFrame from './AuthFrame.svelte';
  import { Button, Field, Input, Notice } from '../lib/ui';
  import { session } from '../lib/session.svelte';
  import { errorMessage } from '../lib/api';

  let email = $state('');
  let password = $state('');
  let busy = $state(false);
  let error = $state('');

  async function submit(event: Event): Promise<void> {
    event.preventDefault();
    if (busy) return;

    busy = true;
    error = '';
    try {
      await session.signIn(email, password);
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }
</script>

<AuthFrame title="Вход" subtitle="Введите почту и пароль.">
  <form onsubmit={submit}>
    {#if error}
      <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
    {/if}

    <Field label="Почта">
      <Input bind:value={email} type="email" autocomplete="username" autofocus required />
    </Field>

    <Field label="Пароль">
      <Input bind:value={password} type="password" autocomplete="current-password" required />
    </Field>

    <Button type="submit" icon="right" {busy}>Войти</Button>
  </form>
</AuthFrame>
