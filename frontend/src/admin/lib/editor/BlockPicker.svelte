<script lang="ts">
  import { Badge, Icon, Input, Modal } from '../ui';

  import type { BlockDefinition } from "./types";

  interface Props {
    open: boolean;
    blocks: BlockDefinition[];
    onclose: () => void;
    onpick: (definition: BlockDefinition) => void;
  }

  let { open, blocks, onclose, onpick }: Props = $props();

  let search = $state('');

  const names: Record<string, string> = {
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

  const descriptions: Record<string, string> = {
    heading: 'Заголовок раздела',
    text: 'Абзацы, списки, формулы',
    quote: 'Отзыв или цитата',
    image: 'Одна картинка с подписью',
    gallery: 'Несколько картинок сеткой',
    button: 'Кнопка со ссылкой',
    hero: 'Крупный экран в начале страницы',
    features: 'Карточки с преимуществами',
    cta: 'Блок с призывом и кнопкой',
    divider: 'Черта между разделами',
    spacer: 'Пустое место',
    form: 'Форма обратной связи',
    embed: 'Карта, видео, плеер'
  };

  const categoryNames: Record<string, string> = {
    text: 'Текст',
    media: 'Картинки',
    layout: 'Разметка',
    interactive: 'Интерактив',
    custom: 'Ваши блоки'
  };

  function nameOf(definition: BlockDefinition): string {
    return definition.name ?? names[definition.key] ?? definition.key;
  }

  function descriptionOf(definition: BlockDefinition): string {
    return definition.description || descriptions[definition.key] || '';
  }

  const grouped = $derived.by(() => {
    const needle = search.trim().toLowerCase();
    const matching = blocks.filter(
      (definition) =>
        !needle ||
        nameOf(definition).toLowerCase().includes(needle) ||
        definition.key.includes(needle)
    );

    const order = ['layout', 'text', 'media', 'interactive', 'custom'];
    return order
      .map((category) => ({
        category,
        title: categoryNames[category] ?? category,
        items: matching.filter((definition) => definition.category === category)
      }))
      .filter((group) => group.items.length > 0);
  });
</script>

<Modal {open} title="Добавить блок" size="lg" {onclose}>
  <div class="mb-4">
    <Input bind:value={search} placeholder="Найти блок…" autofocus />
  </div>

  {#if grouped.length === 0}
    <p class="text-sm text-muted">Ничего не нашлось.</p>
  {:else}
    <div class="space-y-5 max-h-[55vh] overflow-y-auto pr-1">
      {#each grouped as group (group.category)}
        <div>
          <div class="ng-label text-faint mb-2">{group.title}</div>
          <div class="grid gap-2 sm:grid-cols-2">
            {#each group.items as definition (definition.key)}
              <button
                type="button"
                disabled={!definition.usable}
                onclick={() => onpick(definition)}
                class="flex items-start gap-3 p-3 border border-line bg-surface-2 text-left
                       transition-colors cursor-pointer hover:border-accent
                       disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <span class="text-accent shrink-0 mt-0.5">
                  <Icon name={definition.icon} size={18} />
                </span>
                <span class="min-w-0">
                  <span class="flex items-center gap-2">
                    <span class="font-bold text-sm">{nameOf(definition)}</span>
                    {#if !definition.builtin}
                      <Badge tone={definition.usable ? 'accent' : 'warning'}>
                        {definition.kind === 'svelte' ? 'Svelte' : 'HTML'}
                      </Badge>
                    {/if}
                  </span>
                  {#if descriptionOf(definition)}
                    <span class="block text-xs text-muted mt-0.5">
                      {descriptionOf(definition)}
                    </span>
                  {:else if !definition.usable}
                    <span class="block text-xs text-warning mt-0.5">
                      Блок ещё собирается
                    </span>
                  {/if}
                </span>
              </button>
            {/each}
          </div>
        </div>
      {/each}
    </div>
  {/if}
</Modal>
