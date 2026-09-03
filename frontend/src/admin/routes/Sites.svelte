<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { router } from '../lib/router.svelte';
  import { Badge, Button, EmptyState, Field, Input, Modal, Notice } from '../lib/ui';

  interface Site {
    id: number;
    name: string;
    slug: string;
    published: boolean;
    pages_count: number;
    primary_domain: string | null;
    url: string;
  }

  let sites = $state<Site[]>([]);
  let loading = $state(true);
  let error = $state('');

  let creating = $state(false);
  let newName = $state('');
  let busy = $state(false);

  async function load(): Promise<void> {
    loading = true;
    try {
      sites = (await api.get<{ sites: Site[] }>('/api/sites')).sites;
      error = '';
    } catch (e) {
      error = errorMessage(e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    load();
  });

  async function create(): Promise<void> {
    if (busy || newName.trim() === '') return;

    busy = true;
    try {
      const result = await api.post<{ site: Site }>('/api/sites', {
        site: { name: newName.trim() }
      });
      creating = false;
      newName = '';
      // Straight into the new site: an empty list of sites is not somewhere
      // anyone wants to land after creating one.
      router.go(`/sites/${result.site.id}/pages`);
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }
</script>

<div class="flex items-center justify-between gap-4 mb-6">
  <div>
    <h1 class="text-2xl font-black tracking-tight">Сайты</h1>
    <p class="text-sm text-muted">Все сайты этой установки Yulia.</p>
  </div>
  <Button icon="plus" onclick={() => (creating = true)}>Новый сайт</Button>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if sites.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState
      icon="layers"
      title="Пока ни одного сайта"
      text="Создайте первый — внутри уже будет главная страница, которую можно сразу открыть в редакторе."
    >
      <Button icon="plus" onclick={() => (creating = true)}>Создать сайт</Button>
    </EmptyState>
  </div>
{:else}
  <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
    {#each sites as site (site.id)}
      <a
        href="/sites/{site.id}/pages"
        onclick={(event) => {
          event.preventDefault();
          router.go(`/sites/${site.id}/pages`);
        }}
        class="block bg-surface border border-line border-l-[3px] border-l-accent p-5
               hover:border-line-strong transition-colors ng-enter"
      >
        <div class="flex items-start justify-between gap-3 mb-2">
          <h2 class="font-bold tracking-tight truncate">{site.name}</h2>
          <Badge tone={site.published ? 'success' : 'neutral'}>
            {site.published ? 'опубликован' : 'черновик'}
          </Badge>
        </div>
        <p class="text-xs text-muted truncate">
          {site.primary_domain ?? `/preview/${site.slug}`}
        </p>
        <p class="text-xs text-faint mt-3">
          {site.pages_count}
          {site.pages_count === 1 ? 'страница' : site.pages_count < 5 ? 'страницы' : 'страниц'}
        </p>
      </a>
    {/each}
  </div>
{/if}

<Modal
  open={creating}
  title="Новый сайт"
  subtitle="Название можно поменять когда угодно."
  onclose={() => (creating = false)}
>
  <Field label="Название сайта" hint="Например: Кофейня «Пар»">
    <Input bind:value={newName} autofocus />
  </Field>

  {#snippet footer()}
    <Button variant="ghost" onclick={() => (creating = false)}>Отмена</Button>
    <Button icon="check" onclick={create} {busy} disabled={newName.trim() === ''}>Создать</Button>
  {/snippet}
</Modal>
