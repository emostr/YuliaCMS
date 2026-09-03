<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { Button, EmptyState, Icon, Notice } from '../lib/ui';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface MediaItem {
    id: number;
    title: string;
    alt: string;
    url: string | null;
    content_type: string | null;
    byte_size: number;
  }

  let items = $state<MediaItem[]>([]);
  let loading = $state(true);
  let uploading = $state(false);
  let error = $state('');
  let fileInput = $state<HTMLInputElement | null>(null);

  async function load(): Promise<void> {
    loading = true;
    try {
      items = (await api.get<{ media: MediaItem[] }>(`/api/sites/${siteId}/media_items`)).media;
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

  async function upload(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    if (files.length === 0) return;

    uploading = true;
    error = '';
    try {
      for (const file of files) {
        const form = new FormData();
        form.append('file', file);
        form.append('title', file.name);
        const result = await api.post<{ media: MediaItem }>(
          `/api/sites/${siteId}/media_items`,
          form
        );
        items = [result.media, ...items];
      }
    } catch (e) {
      error = errorMessage(e);
    } finally {
      uploading = false;
      input.value = '';
    }
  }

  async function remove(item: MediaItem): Promise<void> {
    if (!confirm(`Удалить «${item.title}»? Страницы, где он стоит, останутся с битой картинкой.`))
      return;

    try {
      await api.delete(`/api/media_items/${item.id}`);
      items = items.filter((candidate) => candidate.id !== item.id);
    } catch (e) {
      error = errorMessage(e);
    }
  }

  function size(bytes: number): string {
    if (bytes < 1024) return `${bytes} Б`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} КБ`;
    return `${(bytes / 1024 / 1024).toFixed(1)} МБ`;
  }
</script>

<div class="flex items-center justify-between gap-4 mb-6">
  <div>
    <h1 class="text-2xl font-black tracking-tight">Файлы</h1>
    <p class="text-sm text-muted">Картинки, которые можно поставить в блоки.</p>
  </div>
  <div>
    <input bind:this={fileInput} type="file" accept="image/*" multiple class="hidden" onchange={upload} />
    <Button icon="plus" busy={uploading} onclick={() => fileInput?.click()}>Загрузить</Button>
  </div>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if items.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState icon="image" title="Файлов нет" text="Загрузите картинки, чтобы ставить их в блоки.">
      <Button icon="plus" onclick={() => fileInput?.click()}>Загрузить</Button>
    </EmptyState>
  </div>
{:else}
  <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
    {#each items as item (item.id)}
      <div class="bg-surface border border-line ng-enter">
        <div class="aspect-square bg-surface-2 overflow-hidden">
          {#if item.url && item.content_type?.startsWith('image/')}
            <img src={item.url} alt={item.alt} class="w-full h-full object-cover" loading="lazy" />
          {:else}
            <span class="flex items-center justify-center h-full text-faint">
              <Icon name="file" size={28} />
            </span>
          {/if}
        </div>
        <div class="p-2.5 flex items-center gap-2">
          <span class="min-w-0 flex-1">
            <span class="block text-xs font-bold truncate">{item.title}</span>
            <span class="block text-[11px] text-faint">{size(item.byte_size)}</span>
          </span>
          <Button size="sm" variant="ghost" icon="trash" onclick={() => remove(item)} />
        </div>
      </div>
    {/each}
  </div>
{/if}
