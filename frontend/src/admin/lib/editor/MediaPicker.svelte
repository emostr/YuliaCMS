<script lang="ts">
  import { api, errorMessage } from '../api';
  import { Button, EmptyState, Icon, Modal, Notice } from '../ui';

  interface MediaItem {
    id: number;
    title: string;
    alt: string;
    url: string | null;
    content_type: string | null;
  }

  interface Props {
    open: boolean;
    siteId: number;
    onclose: () => void;
    onpick: (item: MediaItem) => void;
  }

  let { open, siteId, onclose, onpick }: Props = $props();

  let items = $state<MediaItem[]>([]);
  let loading = $state(false);
  let uploading = $state(false);
  let error = $state('');
  let fileInput = $state<HTMLInputElement | null>(null);

  $effect(() => {
    if (!open) return;

    loading = true;
    api
      .get<{ media: MediaItem[] }>(`/api/sites/${siteId}/media_items`)
      .then((result) => (items = result.media))
      .catch((e) => (error = errorMessage(e)))
      .finally(() => (loading = false));
  });

  async function upload(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    uploading = true;
    error = '';
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('title', file.name);

      const result = await api.post<{ media: MediaItem }>(
        `/api/sites/${siteId}/media_items`,
        form
      );
      items = [result.media, ...items];
      onpick(result.media);
    } catch (e) {
      error = errorMessage(e);
    } finally {
      uploading = false;
      input.value = '';
    }
  }
</script>

<Modal {open} title="Файлы" subtitle="Выберите картинку или загрузите новую" size="lg" {onclose}>
  {#if error}
    <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
  {/if}

  <div class="mb-4">
    <input
      bind:this={fileInput}
      type="file"
      accept="image/*"
      class="hidden"
      onchange={upload}
    />
    <Button icon="plus" busy={uploading} onclick={() => fileInput?.click()}>Загрузить</Button>
  </div>

  {#if loading}
    <p class="text-sm text-muted">Загрузка…</p>
  {:else if items.length === 0}
    <EmptyState icon="image" title="Файлов пока нет" text="Загрузите первую картинку." />
  {:else}
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 max-h-[50vh] overflow-y-auto">
      {#each items as item (item.id)}
        <button
          type="button"
          onclick={() => onpick(item)}
          class="group relative aspect-square border border-line bg-surface-2 overflow-hidden
                 hover:border-accent transition-colors cursor-pointer"
          title={item.title}
        >
          {#if item.url && item.content_type?.startsWith('image/')}
            <img src={item.url} alt={item.alt} class="w-full h-full object-cover" />
          {:else}
            <span class="flex items-center justify-center h-full text-faint">
              <Icon name="file" size={24} />
            </span>
          {/if}
        </button>
      {/each}
    </div>
  {/if}
</Modal>
