<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { router } from '../lib/router.svelte';
  import { Badge, Button, EmptyState, Icon, Notice } from '../lib/ui';
  import BlockPicker from "../lib/editor/BlockPicker.svelte";
  import Properties from "../lib/editor/Properties.svelte";
  import type { Block, BlockDefinition, FieldSpec } from "../lib/editor/types";

  interface Props {
    siteId: number;
    pageId: number;
  }

  let { siteId, pageId }: Props = $props();

  interface Page {
    id: number;
    title: string;
    slug: string;
    path: string;
    status: string;
    home: boolean;
    draft_content: Block[];
    has_unpublished_changes: boolean;
  }

  interface Site {
    id: number;
    name: string;
    slug: string;
  }

  let page = $state<Page | null>(null);
  let site = $state<Site | null>(null);
  let blocks = $state<Block[]>([]);
  let definitions = $state<BlockDefinition[]>([]);

  let selectedId = $state<string | null>(null);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');

  let saving = $state(false);
  let publishing = $state(false);
  let dirty = $state(false);

  let picking = $state(false);
  let showPreview = $state(false);
  let previewKey = $state(0);

  let dragIndex = $state<number | null>(null);
  let dropIndex = $state<number | null>(null);

  const selected = $derived(blocks.find((block) => block.id === selectedId) ?? null);

  const selectedDefinition = $derived(
    selected ? (definitions.find((d) => d.key === selected.type) ?? null) : null
  );

  const selectedFields = $derived<FieldSpec[]>(
    selectedDefinition
      ? ((selectedDefinition as unknown as { fields: FieldSpec[] }).fields ?? [])
      : []
  );

  const blockNames: Record<string, string> = {
    heading: 'Заголовок',
    text: 'Текст',
    quote: 'Цитата',
    image: 'Картинка',
    gallery: 'Галерея',
    button: 'Кнопка',
    hero: 'Обложка',
    features: 'Преимущества',
    cta: 'Призыв к действию',
    divider: 'Разделитель',
    spacer: 'Отступ',
    form: 'Форма',
    embed: 'Встроенный код'
  };

  function nameOf(block: Block): string {
    const definition = definitions.find((d) => d.key === block.type);
    return definition?.name ?? blockNames[block.type] ?? block.type;
  }

  function iconOf(block: Block): string {
    return definitions.find((d) => d.key === block.type)?.icon ?? 'puzzle';
  }

  // A one-line summary so the block list reads like the page rather than like
  // a list of block types.
  function summaryOf(block: Block): string {
    const candidates = ['title', 'text', 'label', 'html', 'caption', 'alt', 'src'];
    for (const key of candidates) {
      const value = block.props[key];
      if (typeof value === 'string' && value.trim()) {
        return value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 60);
      }
    }
    return '';
  }

  async function load(): Promise<void> {
    loading = true;
    try {
      const [pageResult, siteResult, blocksResult] = await Promise.all([
        api.get<{ page: Page }>(`/api/pages/${pageId}`),
        api.get<{ site: Site }>(`/api/sites/${siteId}`),
        api.get<{ builtin: BlockDefinition[]; custom: BlockDefinition[] }>(
          `/api/sites/${siteId}/blocks`
        )
      ]);

      page = pageResult.page;
      site = siteResult.site;
      blocks = pageResult.page.draft_content ?? [];
      definitions = [...blocksResult.builtin, ...blocksResult.custom];
      selectedId = blocks[0]?.id ?? null;
      error = '';
    } catch (e) {
      error = errorMessage(e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    void pageId;
    load();
  });

  // Ctrl+S is what people press, whether or not an application asked them to.
  function onkeydown(event: KeyboardEvent): void {
    if ((event.metaKey || event.ctrlKey) && event.key === 's') {
      event.preventDefault();
      save();
    }
  }

  function touch(): void {
    dirty = true;
    notice = '';
  }

  function updateProp(key: string, value: unknown): void {
    if (!selected) return;

    blocks = blocks.map((block) =>
      block.id === selected.id ? { ...block, props: { ...block.props, [key]: value } } : block
    );
    touch();
  }

  function addBlock(definition: BlockDefinition): void {
    const block: Block = {
      id: crypto.randomUUID(),
      type: definition.key,
      props: { ...definition.defaults }
    };

    // A new block lands after the selected one, which is where somebody
    // pointing at a spot on the page expects it to appear.
    const at = selectedId ? blocks.findIndex((b) => b.id === selectedId) + 1 : blocks.length;
    blocks = [...blocks.slice(0, at), block, ...blocks.slice(at)];
    selectedId = block.id;
    picking = false;
    touch();
  }

  function removeBlock(id: string): void {
    const index = blocks.findIndex((block) => block.id === id);
    blocks = blocks.filter((block) => block.id !== id);
    selectedId = blocks[Math.max(0, index - 1)]?.id ?? null;
    touch();
  }

  function duplicateBlock(id: string): void {
    const index = blocks.findIndex((block) => block.id === id);
    if (index < 0) return;

    const copy: Block = {
      id: crypto.randomUUID(),
      type: blocks[index].type,
      props: structuredClone(blocks[index].props)
    };
    blocks = [...blocks.slice(0, index + 1), copy, ...blocks.slice(index + 1)];
    selectedId = copy.id;
    touch();
  }

  function move(index: number, delta: number): void {
    const target = index + delta;
    if (target < 0 || target >= blocks.length) return;

    const next = [...blocks];
    [next[index], next[target]] = [next[target], next[index]];
    blocks = next;
    touch();
  }

  function drop(index: number): void {
    if (dragIndex === null || dragIndex === index) {
      dragIndex = null;
      dropIndex = null;
      return;
    }

    const next = [...blocks];
    const [moved] = next.splice(dragIndex, 1);
    next.splice(index, 0, moved);
    blocks = next;
    dragIndex = null;
    dropIndex = null;
    touch();
  }

  async function save(): Promise<void> {
    if (saving || !page) return;

    saving = true;
    error = '';
    try {
      const result = await api.patch<{ page: Page }>(`/api/pages/${page.id}`, {
        page: { draft_content: blocks }
      });
      page = result.page;
      dirty = false;
      notice = 'Черновик сохранён.';
      previewKey += 1;
    } catch (e) {
      error = errorMessage(e);
    } finally {
      saving = false;
    }
  }

  async function publish(): Promise<void> {
    if (publishing || !page) return;

    publishing = true;
    error = '';
    try {
      // Saving first, so publishing can never put an older draft live than the
      // one on screen.
      await api.patch(`/api/pages/${page.id}`, { page: { draft_content: blocks } });
      const result = await api.post<{ page: Page }>(`/api/pages/${page.id}/publish`);
      page = result.page;
      dirty = false;
      notice = 'Страница опубликована.';
      previewKey += 1;
    } catch (e) {
      error = errorMessage(e);
    } finally {
      publishing = false;
    }
  }

  const previewUrl = $derived(
    site && page ? `/preview/${site.slug}${page.path === '/' ? '' : page.path}` : ''
  );
</script>

<svelte:window {onkeydown} />

<div class="h-screen flex flex-col overflow-hidden">
  <header class="flex items-center gap-3 px-4 h-14 border-b border-line bg-surface shrink-0">
    <Button
      variant="ghost"
      icon="left"
      title="К списку страниц"
      onclick={() => router.go(`/sites/${siteId}/pages`)}
    />

    <div class="min-w-0 flex-1">
      <div class="flex items-center gap-2">
        <span class="font-bold tracking-tight truncate">{page?.title ?? 'Страница'}</span>
        {#if dirty}
          <Badge tone="warning">не сохранено</Badge>
        {:else if page?.has_unpublished_changes}
          <Badge tone="warning">не опубликовано</Badge>
        {:else if page?.status === 'published'}
          <Badge tone="success">опубликована</Badge>
        {/if}
      </div>
      <span class="text-xs text-muted font-mono">{page?.path ?? ''}</span>
    </div>

    <Button
      variant="ghost"
      icon="eye"
      title={showPreview ? 'Скрыть предпросмотр' : 'Показать предпросмотр'}
      onclick={() => {
        showPreview = !showPreview;
        if (showPreview) previewKey += 1;
      }}
    />
    <Button variant="outline" icon="check" busy={saving} onclick={save}>Сохранить</Button>
    <Button icon="send" busy={publishing} onclick={publish}>Опубликовать</Button>
  </header>

  {#if error}
    <div class="px-4 py-2 shrink-0"><Notice tone="danger">{error}</Notice></div>
  {:else if notice}
    <div class="px-4 py-2 shrink-0"><Notice tone="success">{notice}</Notice></div>
  {/if}

  {#if loading}
    <div class="flex-1 flex items-center justify-center text-muted text-sm">Загрузка…</div>
  {:else}
    <div class="flex-1 flex min-h-0">
      <!-- Block list -->
      <div class="w-full sm:w-80 shrink-0 border-r border-line flex flex-col min-h-0">
        <div class="flex items-center justify-between px-4 h-11 border-b border-line shrink-0">
          <span class="ng-label text-muted">Блоки</span>
          <Button size="sm" icon="plus" onclick={() => (picking = true)}>Добавить</Button>
        </div>

        <div class="flex-1 overflow-y-auto">
          {#if blocks.length === 0}
            <EmptyState
              icon="layers"
              title="Страница пустая"
              text="Добавьте первый блок — например, обложку."
            >
              <Button icon="plus" onclick={() => (picking = true)}>Добавить блок</Button>
            </EmptyState>
          {:else}
            {#each blocks as block, index (block.id)}
              <div
                role="button"
                tabindex="0"
                draggable="true"
                ondragstart={() => (dragIndex = index)}
                ondragover={(event) => {
                  event.preventDefault();
                  dropIndex = index;
                }}
                ondragleave={() => (dropIndex = null)}
                ondrop={(event) => {
                  event.preventDefault();
                  drop(index);
                }}
                ondragend={() => {
                  dragIndex = null;
                  dropIndex = null;
                }}
                onclick={() => (selectedId = block.id)}
                onkeydown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    selectedId = block.id;
                  }
                }}
                class="group flex items-center gap-2.5 px-3 py-2.5 border-b border-line
                       cursor-pointer transition-colors
                       {selectedId === block.id
                  ? 'bg-surface-2 border-l-[3px] border-l-accent pl-[9px]'
                  : 'hover:bg-surface-2 border-l-[3px] border-l-transparent pl-[9px]'}
                       {dropIndex === index && dragIndex !== index ? 'border-t-2 border-t-accent' : ''}
                       {dragIndex === index ? 'opacity-40' : ''}"
              >
                <span class="text-faint cursor-grab shrink-0" title="Перетащите, чтобы переставить">
                  <Icon name="drag" size={14} />
                </span>
                <span class="text-accent shrink-0"><Icon name={iconOf(block)} size={15} /></span>

                <span class="min-w-0 flex-1">
                  <span class="block text-sm font-bold truncate">{nameOf(block)}</span>
                  {#if summaryOf(block)}
                    <span class="block text-xs text-muted truncate">{summaryOf(block)}</span>
                  {/if}
                </span>

                <span class="flex gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                  <Button
                    size="sm"
                    variant="ghost"
                    icon="up"
                    title="Выше"
                    onclick={() => move(index, -1)}
                  />
                  <Button
                    size="sm"
                    variant="ghost"
                    icon="down"
                    title="Ниже"
                    onclick={() => move(index, 1)}
                  />
                  <Button
                    size="sm"
                    variant="ghost"
                    icon="copy"
                    title="Дублировать"
                    onclick={() => duplicateBlock(block.id)}
                  />
                  <Button
                    size="sm"
                    variant="ghost"
                    icon="trash"
                    title="Удалить"
                    onclick={() => removeBlock(block.id)}
                  />
                </span>
              </div>
            {/each}
          {/if}
        </div>
      </div>

      <!-- Properties, or the preview when it is open -->
      <div class="hidden sm:flex flex-1 min-w-0">
        {#if showPreview}
          <div class="flex-1 bg-surface-2 p-4 min-w-0">
            {#key previewKey}
              <iframe
                src={previewUrl}
                title="Предпросмотр страницы"
                class="w-full h-full border border-line bg-white"
              ></iframe>
            {/key}
          </div>
        {/if}

        <div class="w-96 shrink-0 overflow-y-auto {showPreview ? 'border-l border-line' : ''}">
          {#if selected && selectedDefinition}
            <div class="px-4 h-11 flex items-center border-b border-line">
              <span class="ng-label text-muted">{nameOf(selected)}</span>
            </div>
            <div class="p-4">
              <Properties
                fields={selectedFields}
                props={selected.props}
                {siteId}
                onchange={updateProp}
              />
            </div>
          {:else if selected}
            <div class="p-4">
              <Notice tone="warning">
                Блок «{selected.type}» больше не доступен. Возможно, он был удалён из списка ваших
                блоков.
              </Notice>
            </div>
          {:else}
            <div class="p-4 text-sm text-muted">
              Выберите блок слева, чтобы настроить его.
            </div>
          {/if}
        </div>
      </div>
    </div>
  {/if}
</div>

<BlockPicker
  open={picking}
  blocks={definitions}
  onclose={() => (picking = false)}
  onpick={addBlock}
/>
