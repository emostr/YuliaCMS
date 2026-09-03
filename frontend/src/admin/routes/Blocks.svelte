<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { Badge, Button, EmptyState, Field, Icon, Input, Modal, Notice, Select } from '../lib/ui';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface SchemaField {
    key: string;
    label: string;
    type: string;
  }

  interface BlockType {
    id: number;
    key: string;
    name: string;
    description: string;
    kind: string;
    enabled: boolean;
    build_status: string;
    usable: boolean;
    schema: SchemaField[];
    template?: string;
    source?: string;
    build_log?: string;
  }

  let blockTypes = $state<BlockType[]>([]);
  let loading = $state(true);
  let error = $state('');

  let editing = $state<BlockType | null>(null);
  let saving = $state(false);

  const STARTER_HTML = `{% comment %}
  Ваш блок. Значения полей лежат в block.<ключ поля>.
  Всё, что не rich text, экранируйте фильтром escape.
{% endcomment %}
<section class="y-features">
  <h2>{{ block.title | escape }}</h2>
  <p>{{ block.text | escape }}</p>
</section>`;

  const STARTER_HTMX = `{% comment %}
  То же самое, но с htmx: кнопка подтягивает кусок HTML с сервера
  и подставляет его вместо себя. JavaScript писать не нужно.
{% endcomment %}
<div class="y-features">
  <h2>{{ block.title | escape }}</h2>
  <button class="y-button y-button-solid"
          hx-get="/{{ block.source_path }}"
          hx-target="closest div"
          hx-swap="innerHTML">
    {{ block.button_label | escape }}
  </button>
</div>`;

  const STARTER_SVELTE = `<script>
  // Значения полей приходят как props.
  let { title = '', start = 0 } = $props();
  let count = $state(Number(start) || 0);
<\/script>

<div class="y-features">
  <h2>{title}</h2>
  <button class="y-button y-button-solid" onclick={() => count++}>
    Нажато {count} раз
  </button>
</div>`;

  async function load(): Promise<void> {
    loading = true;
    try {
      blockTypes = (
        await api.get<{ block_types: BlockType[] }>(`/api/sites/${siteId}/block_types`)
      ).block_types;
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

  function startNew(kind: string): void {
    editing = {
      id: 0,
      key: '',
      name: '',
      description: '',
      kind,
      enabled: true,
      build_status: kind === 'svelte' ? 'pending' : 'ready',
      usable: kind !== 'svelte',
      schema: [{ key: 'title', label: 'Заголовок', type: 'text' }],
      template: kind === 'html' ? STARTER_HTML : '',
      source: kind === 'svelte' ? STARTER_SVELTE : ''
    };
  }

  async function open(blockType: BlockType): Promise<void> {
    try {
      const result = await api.get<{ block_type: BlockType }>(`/api/block_types/${blockType.id}`);
      editing = result.block_type;
    } catch (e) {
      error = errorMessage(e);
    }
  }

  async function save(): Promise<void> {
    if (!editing || saving) return;

    saving = true;
    error = '';
    try {
      const payload = {
        block_type: {
          key: editing.key,
          name: editing.name,
          description: editing.description,
          kind: editing.kind,
          template: editing.template ?? '',
          source: editing.source ?? '',
          enabled: editing.enabled,
          schema: editing.schema
        }
      };

      if (editing.id === 0) {
        await api.post(`/api/sites/${siteId}/block_types`, payload);
      } else {
        await api.patch(`/api/block_types/${editing.id}`, payload);
      }

      editing = null;
      await load();
    } catch (e) {
      error = errorMessage(e);
    } finally {
      saving = false;
    }
  }

  async function remove(blockType: BlockType): Promise<void> {
    if (!confirm(`Удалить блок «${blockType.name}»?`)) return;

    try {
      await api.delete(`/api/block_types/${blockType.id}`);
      blockTypes = blockTypes.filter((candidate) => candidate.id !== blockType.id);
    } catch (e) {
      error = errorMessage(e);
    }
  }

  function addField(): void {
    if (!editing) return;
    editing.schema = [...editing.schema, { key: '', label: '', type: 'text' }];
  }

  function removeField(index: number): void {
    if (!editing) return;
    editing.schema = editing.schema.filter((_, position) => position !== index);
  }

  const fieldTypes = [
    { value: 'text', label: 'строка' },
    { value: 'textarea', label: 'много текста' },
    { value: 'richtext', label: 'форматированный текст' },
    { value: 'number', label: 'число' },
    { value: 'boolean', label: 'да / нет' },
    { value: 'select', label: 'выбор из списка' },
    { value: 'image', label: 'картинка' },
    { value: 'link', label: 'ссылка' },
    { value: 'color', label: 'цвет' }
  ];
</script>

<div class="flex items-start justify-between gap-4 mb-6">
  <div>
    <h1 class="text-2xl font-black tracking-tight">Ваши блоки</h1>
    <p class="text-sm text-muted">
      Когда готовых блоков не хватает, напишите свой. Рекомендуемый путь — HTML с htmx: он
      работает на сервере и не требует JavaScript.
    </p>
  </div>
  <div class="flex gap-2 shrink-0">
    <Button variant="outline" icon="code" onclick={() => startNew('html')}>HTML + htmx</Button>
    <Button variant="outline" icon="puzzle" onclick={() => startNew('svelte')}>Svelte</Button>
  </div>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if blockTypes.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState
      icon="puzzle"
      title="Своих блоков пока нет"
      text="Готовых блоков хватает большинству сайтов. Свой понадобится, если нужно что-то, чего в наборе нет."
    >
      <Button icon="code" onclick={() => startNew('html')}>Написать блок</Button>
    </EmptyState>
  </div>
{:else}
  <div class="bg-surface border border-line divide-y divide-line">
    {#each blockTypes as blockType (blockType.id)}
      <div class="flex items-center gap-3 px-5 py-4">
        <span class="text-accent"><Icon name="puzzle" size={16} /></span>
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <span class="font-bold truncate">{blockType.name}</span>
            <Badge tone={blockType.kind === 'svelte' ? 'accent' : 'neutral'}>
              {blockType.kind === 'svelte' ? 'Svelte' : 'HTML'}
            </Badge>
            {#if blockType.kind === 'svelte'}
              {#if blockType.build_status === 'ready'}
                <Badge tone="success">собран</Badge>
              {:else if blockType.build_status === 'failed'}
                <Badge tone="danger">ошибка сборки</Badge>
              {:else}
                <Badge tone="warning">собирается</Badge>
              {/if}
            {/if}
          </div>
          <span class="text-xs text-muted font-mono">{blockType.key}</span>
        </div>

        <Button size="sm" variant="ghost" icon="edit" onclick={() => open(blockType)} />
        <Button size="sm" variant="ghost" icon="trash" onclick={() => remove(blockType)} />
      </div>
    {/each}
  </div>
{/if}

<Modal
  open={editing !== null}
  title={editing?.id === 0 ? 'Новый блок' : 'Правка блока'}
  subtitle={editing?.kind === 'svelte'
    ? 'Компонент Svelte: собирается на сервере и оживает только на тех страницах, где стоит'
    : 'Шаблон на Liquid: рендерится сервером, htmx добавляет интерактив'}
  size="xl"
  onclose={() => (editing = null)}
>
  {#if editing}
    <div class="grid gap-4 lg:grid-cols-2">
      <div>
        <Field label="Название" hint="Так блок будет называться в списке.">
          <Input bind:value={editing.name} />
        </Field>
        <Field label="Ключ" hint="Латиницей, через дефис. Менять после публикации не стоит.">
          <Input bind:value={editing.key} />
        </Field>
        <Field label="Описание">
          <Input bind:value={editing.description} />
        </Field>

        <div class="mb-2 flex items-center justify-between">
          <span class="ng-label text-muted">Поля блока</span>
          <Button size="sm" variant="outline" icon="plus" onclick={addField}>Поле</Button>
        </div>

        {#each editing.schema as field, index (index)}
          <div class="flex gap-1.5 mb-1.5">
            <input
              bind:value={field.key}
              placeholder="ключ"
              class="w-24 h-9 px-2 bg-surface-2 border border-line text-xs font-mono
                     focus:outline-none focus:border-accent"
            />
            <input
              bind:value={field.label}
              placeholder="подпись"
              class="flex-1 h-9 px-2 bg-surface-2 border border-line text-xs
                     focus:outline-none focus:border-accent"
            />
            <select
              bind:value={field.type}
              class="w-40 h-9 px-2 bg-surface-2 border border-line text-xs cursor-pointer
                     focus:outline-none focus:border-accent"
            >
              {#each fieldTypes as type (type.value)}
                <option value={type.value}>{type.label}</option>
              {/each}
            </select>
            <Button size="sm" variant="ghost" icon="trash" onclick={() => removeField(index)} />
          </div>
        {/each}
      </div>

      <div>
        {#if editing.kind === 'html'}
          <Field label="Шаблон">
            <textarea
              bind:value={editing.template}
              rows="18"
              spellcheck="false"
              class="w-full px-3 py-2 bg-surface-2 border border-line text-ink font-mono text-xs
                     leading-relaxed resize-y focus:outline-none focus:border-accent"
            ></textarea>
          </Field>
          <div class="flex gap-2">
            <Button
              size="sm"
              variant="ghost"
              onclick={() => editing && (editing.template = STARTER_HTML)}
            >
              Пример без htmx
            </Button>
            <Button
              size="sm"
              variant="ghost"
              onclick={() => editing && (editing.template = STARTER_HTMX)}
            >
              Пример с htmx
            </Button>
          </div>
        {:else}
          <Field label="Компонент Svelte">
            <textarea
              bind:value={editing.source}
              rows="18"
              spellcheck="false"
              class="w-full px-3 py-2 bg-surface-2 border border-line text-ink font-mono text-xs
                     leading-relaxed resize-y focus:outline-none focus:border-accent"
            ></textarea>
          </Field>

          {#if editing.build_status === 'failed' && editing.build_log}
            <Notice tone="danger">
              <span class="block font-bold mb-1">Сборка не прошла</span>
              <pre class="text-xs whitespace-pre-wrap font-mono">{editing.build_log}</pre>
            </Notice>
          {/if}
        {/if}
      </div>
    </div>
  {/if}

  {#snippet footer()}
    <Button variant="ghost" onclick={() => (editing = null)}>Отмена</Button>
    <Button icon="check" busy={saving} onclick={save}>Сохранить</Button>
  {/snippet}
</Modal>
