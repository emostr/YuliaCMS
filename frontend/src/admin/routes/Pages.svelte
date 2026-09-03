<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { router } from '../lib/router.svelte';
  import { Badge, Button, EmptyState, Field, Icon, Input, Modal, Notice } from '../lib/ui';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface Page {
    id: number;
    title: string;
    path: string;
    status: string;
    home: boolean;
    has_unpublished_changes: boolean;
    updated_at: string;
  }

  interface Site {
    id: number;
    name: string;
    slug: string;
    url: string;
    primary_domain: string | null;
  }

  let site = $state<Site | null>(null);
  let pages = $state<Page[]>([]);
  let loading = $state(true);
  let error = $state('');

  let creating = $state(false);
  let newTitle = $state('');
  let busy = $state(false);

  async function load(): Promise<void> {
    loading = true;
    try {
      const [siteResult, pagesResult] = await Promise.all([
        api.get<{ site: Site }>(`/api/sites/${siteId}`),
        api.get<{ pages: Page[] }>(`/api/sites/${siteId}/pages`)
      ]);
      site = siteResult.site;
      pages = pagesResult.pages;
      error = '';
    } catch (e) {
      error = errorMessage(e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    void siteId;
    load();
  });

  async function create(): Promise<void> {
    if (busy || newTitle.trim() === '') return;

    busy = true;
    try {
      const result = await api.post<{ page: Page }>(`/api/sites/${siteId}/pages`, {
        page: { title: newTitle.trim() }
      });
      creating = false;
      newTitle = '';
      router.go(`/sites/${siteId}/pages/${result.page.id}`);
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }

  async function remove(page: Page): Promise<void> {
    if (!confirm(`Удалить страницу «${page.title}»? Это не отменить.`)) return;

    try {
      await api.delete(`/api/pages/${page.id}`);
      pages = pages.filter((candidate) => candidate.id !== page.id);
    } catch (e) {
      error = errorMessage(e);
    }
  }

  const previewBase = $derived(site ? (site.primary_domain ? site.url : `/preview/${site.slug}`) : '');
</script>

<div class="flex items-center justify-between gap-4 mb-6">
  <div class="min-w-0">
    <h1 class="text-2xl font-black tracking-tight truncate">{site?.name ?? 'Сайт'}</h1>
    <p class="text-sm text-muted">Страницы сайта.</p>
  </div>
  <div class="flex gap-2 shrink-0">
    {#if previewBase}
      <a
        href={previewBase}
        target="_blank"
        rel="noopener"
        class="inline-flex items-center gap-2 h-10 px-4 border border-line-strong text-sm
               font-bold hover:border-accent hover:text-accent transition-colors"
      >
        <Icon name="eye" size={15} />
        Открыть сайт
      </a>
    {/if}
    <Button icon="plus" onclick={() => (creating = true)}>Страница</Button>
  </div>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if pages.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState icon="file" title="Страниц нет" text="Создайте первую и соберите её из блоков.">
      <Button icon="plus" onclick={() => (creating = true)}>Создать страницу</Button>
    </EmptyState>
  </div>
{:else}
  <div class="bg-surface border border-line divide-y divide-line ng-enter">
    {#each pages as page (page.id)}
      <div class="flex items-center gap-4 px-5 py-3.5 hover:bg-surface-2 transition-colors">
        <a
          href="/sites/{siteId}/pages/{page.id}"
          onclick={(event) => {
            event.preventDefault();
            router.go(`/sites/${siteId}/pages/${page.id}`);
          }}
          class="flex-1 min-w-0"
        >
          <div class="flex items-center gap-2">
            <span class="font-bold truncate">{page.title}</span>
            {#if page.home}
              <Badge tone="accent">главная</Badge>
            {/if}
          </div>
          <span class="text-xs text-muted font-mono">{page.path}</span>
        </a>

        <div class="flex items-center gap-2 shrink-0">
          {#if page.status === 'published'}
            {#if page.has_unpublished_changes}
              <Badge tone="warning">есть правки</Badge>
            {:else}
              <Badge tone="success">опубликована</Badge>
            {/if}
          {:else}
            <Badge>черновик</Badge>
          {/if}

          <Button
            variant="ghost"
            size="sm"
            icon="edit"
            title="Редактировать"
            onclick={() => router.go(`/sites/${siteId}/pages/${page.id}`)}
          />
          {#if !page.home}
            <Button
              variant="ghost"
              size="sm"
              icon="trash"
              title="Удалить"
              onclick={() => remove(page)}
            />
          {/if}
        </div>
      </div>
    {/each}
  </div>
{/if}

<Modal open={creating} title="Новая страница" onclose={() => (creating = false)}>
  <Field label="Заголовок" hint="Адрес получится сам, его можно поправить потом.">
    <Input bind:value={newTitle} autofocus />
  </Field>

  {#snippet footer()}
    <Button variant="ghost" onclick={() => (creating = false)}>Отмена</Button>
    <Button icon="check" onclick={create} {busy} disabled={newTitle.trim() === ''}>Создать</Button>
  {/snippet}
</Modal>
