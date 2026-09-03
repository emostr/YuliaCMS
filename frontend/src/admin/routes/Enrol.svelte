<script lang="ts">
  import AuthFrame from './AuthFrame.svelte';
  import { Button, Field, Input, Notice, Icon } from '../lib/ui';
  import { session } from '../lib/session.svelte';
  import { api, errorMessage } from '../lib/api';

  interface Enrolment {
    secret: string;
    uri: string;
    qr_svg: string;
  }

  let enrolment = $state<Enrolment | null>(null);
  let code = $state('');
  let recoveryCodes = $state<string[]>([]);
  let busy = $state(false);
  let error = $state('');
  let copied = $state(false);

  // The QR is fetched as soon as this screen opens: there is nothing else to
  // decide first, and one fewer button is one fewer thing to explain.
  $effect(() => {
    if (enrolment) return;

    api
      .post<Enrolment>('/api/second_factor/totp')
      .then((result) => (enrolment = result))
      .catch((e) => (error = errorMessage(e)));
  });

  async function confirm(event: Event): Promise<void> {
    event.preventDefault();
    if (busy || code.trim() === '') return;

    busy = true;
    error = '';
    try {
      const result = await api.post<{ recovery_codes: string[] }>(
        '/api/second_factor/confirm_totp',
        { code: code.trim() }
      );
      recoveryCodes = result.recovery_codes;
    } catch (e) {
      error = errorMessage(e);
      code = '';
    } finally {
      busy = false;
    }
  }

  async function copyCodes(): Promise<void> {
    try {
      await navigator.clipboard.writeText(recoveryCodes.join('\n'));
      copied = true;
      setTimeout(() => (copied = false), 2000);
    } catch {
      // Clipboard access can be refused; the codes are on screen either way.
    }
  }
</script>

{#if recoveryCodes.length}
  <AuthFrame
    title="Сохраните коды восстановления"
    subtitle="Каждый код срабатывает один раз. Они понадобятся, если телефон потеряется."
  >
    <div class="grid grid-cols-2 gap-2 mb-5 font-mono text-sm">
      {#each recoveryCodes as recoveryCode (recoveryCode)}
        <div class="px-3 py-2 bg-surface-2 border border-line text-center tracking-wider">
          {recoveryCode}
        </div>
      {/each}
    </div>

    <div class="mb-5">
      <Notice tone="warning">
        Больше мы их не покажем: на сервере хранятся только отпечатки. Распечатайте или положите
        в менеджер паролей.
      </Notice>
    </div>

    <div class="flex gap-2">
      <Button variant="outline" icon={copied ? 'check' : 'copy'} onclick={copyCodes}>
        {copied ? 'Скопировано' : 'Скопировать'}
      </Button>
      <Button icon="right" onclick={() => session.finishEnrolment()}>Перейти в админку</Button>
    </div>
  </AuthFrame>
{:else}
  <AuthFrame
    step="Шаг 2 из 2"
    title="Защитите вход"
    subtitle="Пароля мало: через админку публикуются все сайты на этом сервере. Привяжите приложение-аутентификатор."
  >
    {#if error}
      <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
    {/if}

    {#if enrolment}
      <div class="flex justify-center mb-4">
        <!-- Rendered on the server so the secret never passes through
             client-side code that could keep a copy. -->
        <div class="bg-white p-3 w-44 h-44 [&>svg]:w-full [&>svg]:h-full">
          {@html enrolment.qr_svg}
        </div>
      </div>

      <p class="text-xs text-muted text-center mb-1">
        Отсканируйте в Google Authenticator, 1Password, Aegis — в любом.
      </p>
      <details class="mb-5 text-center">
        <summary class="text-xs text-faint cursor-pointer hover:text-muted">
          Не получается отсканировать?
        </summary>
        <code class="block mt-2 px-3 py-2 bg-surface-2 border border-line text-xs break-all">
          {enrolment.secret}
        </code>
      </details>

      <form onsubmit={confirm}>
        <Field label="Введите код из приложения" hint="Так мы убедимся, что оно настроено верно.">
          <Input
            bind:value={code}
            inputmode="numeric"
            autocomplete="one-time-code"
            placeholder="000000"
            autofocus
            required
          />
        </Field>

        <Button type="submit" icon="shield" {busy}>Включить защиту</Button>
      </form>
    {:else}
      <div class="flex items-center gap-2 text-muted text-sm py-8 justify-center">
        <Icon name="refresh" size={16} class="animate-spin" />
        Готовим QR-код…
      </div>
    {/if}
  </AuthFrame>
{/if}
