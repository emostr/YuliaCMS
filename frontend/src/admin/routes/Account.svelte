<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { session } from '../lib/session.svelte';
  import { Badge, Button, Card, Notice } from '../lib/ui';

  interface Status {
    enrolled: boolean;
    totp: boolean;
    passkeys: number;
    recovery_codes_left: number;
  }

  let status = $state<Status | null>(null);
  let codes = $state<string[]>([]);
  let error = $state('');
  let busy = $state(false);

  $effect(() => {
    api
      .get<Status>('/api/second_factor')
      .then((result) => (status = result))
      .catch((e) => (error = errorMessage(e)));
  });

  async function regenerate(): Promise<void> {
    if (busy) return;
    if (!confirm('Старые коды восстановления перестанут работать. Продолжить?')) return;

    busy = true;
    try {
      const result = await api.post<{ recovery_codes: string[] }>(
        '/api/second_factor/recovery_codes'
      );
      codes = result.recovery_codes;
      if (status) status.recovery_codes_left = result.recovery_codes.length;
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }
</script>

<div class="mb-6">
  <h1 class="text-2xl font-black tracking-tight">Учётная запись</h1>
  <p class="text-sm text-muted">{session.user?.email}</p>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

<div class="grid gap-4 lg:grid-cols-2">
  <Card title="Защита входа" accent>
    {#if status}
      <div class="space-y-3 text-sm">
        <div class="flex items-center justify-between">
          <span>Приложение-аутентификатор</span>
          <Badge tone={status.totp ? 'success' : 'warning'}>
            {status.totp ? 'подключено' : 'не подключено'}
          </Badge>
        </div>
        <div class="flex items-center justify-between">
          <span>Passkey</span>
          <Badge tone={status.passkeys > 0 ? 'success' : 'neutral'}>
            {status.passkeys > 0 ? `${status.passkeys} шт.` : 'нет'}
          </Badge>
        </div>
        <div class="flex items-center justify-between">
          <span>Кодов восстановления осталось</span>
          <Badge tone={status.recovery_codes_left > 2 ? 'neutral' : 'warning'}>
            {status.recovery_codes_left}
          </Badge>
        </div>
      </div>
    {:else}
      <p class="text-sm text-muted">Загрузка…</p>
    {/if}
  </Card>

  <Card title="Коды восстановления">
    {#if codes.length}
      <div class="grid grid-cols-2 gap-2 mb-4 font-mono text-sm">
        {#each codes as code (code)}
          <div class="px-3 py-2 bg-surface-2 border border-line text-center tracking-wider">
            {code}
          </div>
        {/each}
      </div>
      <Notice tone="warning">Запишите их сейчас — больше мы их не покажем.</Notice>
    {:else}
      <p class="text-sm text-muted mb-4">
        Пригодятся, если телефон с аутентификатором потеряется. Каждый срабатывает один раз.
      </p>
      <Button variant="outline" icon="key" {busy} onclick={regenerate}>
        Сгенерировать новые
      </Button>
    {/if}
  </Card>
</div>
