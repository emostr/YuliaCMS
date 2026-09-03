<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { Badge, EmptyState, Notice } from '../lib/ui';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface Submission {
    id: number;
    fields: Record<string, string>;
    page_title: string | null;
    created_at: string;
    read: boolean;
  }

  let submissions = $state<Submission[]>([]);
  let loading = $state(true);
  let error = $state('');

  $effect(() => {
    void siteId;
    loading = true;
    api
      .get<{ submissions: Submission[] }>(`/api/sites/${siteId}/form_submissions`)
      .then((result) => (submissions = result.submissions))
      .catch((e) => (error = errorMessage(e)))
      .finally(() => (loading = false));
  });

  const labels: Record<string, string> = {
    name: 'Имя',
    email: 'Почта',
    phone: 'Телефон',
    tel: 'Телефон',
    message: 'Сообщение'
  };

  function when(iso: string): string {
    return new Date(iso).toLocaleString('ru-RU', {
      day: 'numeric',
      month: 'long',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
</script>

<div class="mb-6">
  <h1 class="text-2xl font-black tracking-tight">Заявки</h1>
  <p class="text-sm text-muted">Что посетители отправили через блок «Форма».</p>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if submissions.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState
      icon="inbox"
      title="Заявок нет"
      text="Как только кто-нибудь заполнит форму на сайте, она появится здесь."
    />
  </div>
{:else}
  <div class="space-y-3">
    {#each submissions as submission (submission.id)}
      <div class="bg-surface border border-line border-l-[3px] border-l-accent p-5 ng-enter">
        <div class="flex items-center gap-3 mb-3">
          <span class="text-xs text-muted">{when(submission.created_at)}</span>
          {#if submission.page_title}
            <Badge>{submission.page_title}</Badge>
          {/if}
        </div>

        <dl class="grid gap-2 sm:grid-cols-[10rem_1fr]">
          {#each Object.entries(submission.fields) as [key, value] (key)}
            <dt class="ng-label text-muted">{labels[key] ?? key}</dt>
            <dd class="text-sm whitespace-pre-wrap break-words">{value}</dd>
          {/each}
        </dl>
      </div>
    {/each}
  </div>
{/if}
