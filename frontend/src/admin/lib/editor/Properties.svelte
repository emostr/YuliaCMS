<script lang="ts">
  import { Button, Field } from '../ui';
  import RichText from './RichText.svelte';
  import MediaPicker from './MediaPicker.svelte';

  import type { FieldSpec } from "./types";

  interface Props {
    fields: FieldSpec[];
    props: Record<string, unknown>;
    siteId: number;
    onchange: (key: string, value: unknown) => void;
  }

  let { fields, props, siteId, onchange }: Props = $props();

  // Which image field is currently choosing a file. Null closes the picker.
  let picking = $state<{ key: string; index: number | null; itemKey?: string } | null>(null);

  const labels: Record<string, string> = {
    text: 'Текст',
    title: 'Заголовок',
    subtitle: 'Подзаголовок',
    html: 'Текст',
    level: 'Уровень',
    align: 'Выравнивание',
    width: 'Ширина',
    columns: 'Колонок',
    src: 'Картинка',
    image: 'Картинка',
    alt: 'Описание картинки',
    caption: 'Подпись',
    label: 'Надпись',
    href: 'Ссылка',
    variant: 'Вид',
    eyebrow: 'Надзаголовок',
    button_label: 'Надпись на кнопке',
    button_href: 'Куда ведёт кнопка',
    items: 'Пункты',
    images: 'Картинки',
    style: 'Стиль',
    size: 'Размер',
    author: 'Автор',
    role: 'Кто это',
    fields: 'Поля формы',
    submit_label: 'Надпись на кнопке',
    success_message: 'Что показать после отправки',
    name: 'Имя поля',
    type: 'Тип',
    required: 'Обязательное'
  };

  function labelFor(spec: FieldSpec): string {
    return spec.label ?? labels[spec.key] ?? spec.key;
  }

  const optionLabels: Record<string, string> = {
    left: 'слева',
    center: 'по центру',
    right: 'справа',
    narrow: 'узкая',
    normal: 'обычная',
    wide: 'широкая',
    full: 'во всю ширину',
    solid: 'заливка',
    outline: 'контур',
    ghost: 'без рамки',
    line: 'линия',
    dots: 'точки',
    space: 'пустота',
    small: 'маленький',
    medium: 'средний',
    large: 'большой',
    text: 'текст',
    email: 'почта',
    tel: 'телефон',
    textarea: 'много текста'
  };

  function selectOptions(spec: FieldSpec) {
    return (spec.options ?? []).map((option) => ({
      value: option,
      label: optionLabels[option] ?? option
    }));
  }

  function listValue(key: string): Record<string, unknown>[] {
    const value = props[key];
    return Array.isArray(value) ? (value as Record<string, unknown>[]) : [];
  }

  function updateListItem(key: string, index: number, itemKey: string, value: unknown): void {
    const list = [...listValue(key)];
    list[index] = { ...list[index], [itemKey]: value };
    onchange(key, list);
  }

  function addListItem(spec: FieldSpec): void {
    const blank: Record<string, unknown> = {};
    for (const item of spec.item_fields ?? []) blank[item.key] = '';
    onchange(spec.key, [...listValue(spec.key), blank]);
  }

  function removeListItem(key: string, index: number): void {
    onchange(
      key,
      listValue(key).filter((_, position) => position !== index)
    );
  }

  function moveListItem(key: string, index: number, delta: number): void {
    const list = [...listValue(key)];
    const target = index + delta;
    if (target < 0 || target >= list.length) return;

    [list[index], list[target]] = [list[target], list[index]];
    onchange(key, list);
  }

  function text(key: string): string {
    const value = props[key];
    return value === undefined || value === null ? '' : String(value);
  }
</script>

{#each fields as spec (spec.key)}
  {#if spec.type === 'richtext'}
    <div class="mb-4">
      <span class="ng-label text-muted block mb-1.5">{labelFor(spec)}</span>
      <RichText value={text(spec.key)} onchange={(html) => onchange(spec.key, html)} />
    </div>
  {:else if spec.type === 'textarea'}
    <Field label={labelFor(spec)}>
      <!-- The value belongs to the page document, not to this component, so it
           is pushed back through onchange rather than two-way bound. -->
      <textarea
        rows="3"
        value={text(spec.key)}
        oninput={(event) => onchange(spec.key, (event.target as HTMLTextAreaElement).value)}
        class="w-full px-3 py-2 bg-surface-2 border border-line text-ink text-sm resize-y
               focus:outline-none focus:border-accent transition-colors placeholder:text-faint"
      ></textarea>
    </Field>
  {:else if spec.type === 'select'}
    <Field label={labelFor(spec)}>
      <select
        value={text(spec.key)}
        onchange={(event) => onchange(spec.key, (event.target as HTMLSelectElement).value)}
        class="w-full h-10 px-3 bg-surface-2 border border-line text-ink text-sm cursor-pointer
               focus:outline-none focus:border-accent transition-colors"
      >
        {#each selectOptions(spec) as option (option.value)}
          <option value={option.value}>{option.label}</option>
        {/each}
      </select>
    </Field>
  {:else if spec.type === 'boolean'}
    <div class="mb-4">
      <label class="inline-flex items-center gap-2.5 cursor-pointer select-none">
        <input
          type="checkbox"
          checked={Boolean(props[spec.key])}
          onchange={(event) => onchange(spec.key, (event.target as HTMLInputElement).checked)}
          class="w-4 h-4 accent-[var(--ng-accent)] cursor-pointer"
        />
        <span class="text-sm">{labelFor(spec)}</span>
      </label>
    </div>
  {:else if spec.type === 'image'}
    <Field label={labelFor(spec)}>
      <div class="flex gap-2">
        <input
          value={text(spec.key)}
          oninput={(event) => onchange(spec.key, (event.target as HTMLInputElement).value)}
          placeholder="/файл.jpg или ссылка"
          class="flex-1 h-10 px-3 bg-surface-2 border border-line text-ink text-sm
                 focus:outline-none focus:border-accent transition-colors placeholder:text-faint"
        />
        <Button
          variant="outline"
          icon="image"
          title="Выбрать файл"
          onclick={() => (picking = { key: spec.key, index: null })}
        />
      </div>
      {#if text(spec.key)}
        <img
          src={text(spec.key)}
          alt=""
          class="mt-2 max-h-32 border border-line object-contain bg-surface-2"
        />
      {/if}
    </Field>
  {:else if spec.type === 'code'}
    <Field label={labelFor(spec)} hint="Вставьте код встраивания — карту, видео, плеер.">
      <textarea
        rows="6"
        value={text(spec.key)}
        oninput={(event) => onchange(spec.key, (event.target as HTMLTextAreaElement).value)}
        class="w-full px-3 py-2 bg-surface-2 border border-line text-ink font-mono text-xs
               leading-relaxed resize-y focus:outline-none focus:border-accent transition-colors"
      ></textarea>
    </Field>
  {:else if spec.type === 'list'}
    <div class="mb-4">
      <div class="flex items-center justify-between mb-2">
        <span class="ng-label text-muted">{labelFor(spec)}</span>
        <Button size="sm" variant="outline" icon="plus" onclick={() => addListItem(spec)}>
          Добавить
        </Button>
      </div>

      {#each listValue(spec.key) as item, index (index)}
        <div class="border border-line bg-surface-2 p-3 mb-2">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs text-faint font-bold">#{index + 1}</span>
            <div class="flex gap-0.5">
              <Button
                size="sm"
                variant="ghost"
                icon="up"
                title="Выше"
                onclick={() => moveListItem(spec.key, index, -1)}
              />
              <Button
                size="sm"
                variant="ghost"
                icon="down"
                title="Ниже"
                onclick={() => moveListItem(spec.key, index, 1)}
              />
              <Button
                size="sm"
                variant="ghost"
                icon="trash"
                title="Удалить"
                onclick={() => removeListItem(spec.key, index)}
              />
            </div>
          </div>

          {#each spec.item_fields ?? [] as itemSpec (itemSpec.key)}
            {#if itemSpec.type === 'boolean'}
              <label class="flex items-center gap-2 mb-2 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={Boolean(item[itemSpec.key])}
                  onchange={(event) =>
                    updateListItem(
                      spec.key,
                      index,
                      itemSpec.key,
                      (event.target as HTMLInputElement).checked
                    )}
                  class="w-4 h-4 accent-[var(--ng-accent)] cursor-pointer"
                />
                <span class="text-xs">{labelFor(itemSpec)}</span>
              </label>
            {:else if itemSpec.type === 'select'}
              <div class="mb-2">
                <span class="ng-label text-faint block mb-1">{labelFor(itemSpec)}</span>
                <select
                  value={String(item[itemSpec.key] ?? '')}
                  onchange={(event) =>
                    updateListItem(
                      spec.key,
                      index,
                      itemSpec.key,
                      (event.target as HTMLSelectElement).value
                    )}
                  class="w-full h-9 px-2 bg-surface border border-line text-ink text-xs
                         cursor-pointer focus:outline-none focus:border-accent"
                >
                  {#each selectOptions(itemSpec) as option (option.value)}
                    <option value={option.value}>{option.label}</option>
                  {/each}
                </select>
              </div>
            {:else if itemSpec.type === 'image'}
              <div class="mb-2">
                <span class="ng-label text-faint block mb-1">{labelFor(itemSpec)}</span>
                <div class="flex gap-1.5">
                  <input
                    value={String(item[itemSpec.key] ?? '')}
                    oninput={(event) =>
                      updateListItem(
                        spec.key,
                        index,
                        itemSpec.key,
                        (event.target as HTMLInputElement).value
                      )}
                    class="flex-1 h-9 px-2 bg-surface border border-line text-ink text-xs
                           focus:outline-none focus:border-accent"
                  />
                  <Button
                    size="sm"
                    variant="outline"
                    icon="image"
                    onclick={() => (picking = { key: spec.key, index, itemKey: itemSpec.key })}
                  />
                </div>
              </div>
            {:else if itemSpec.type === 'textarea'}
              <div class="mb-2">
                <span class="ng-label text-faint block mb-1">{labelFor(itemSpec)}</span>
                <textarea
                  rows="2"
                  value={String(item[itemSpec.key] ?? '')}
                  oninput={(event) =>
                    updateListItem(
                      spec.key,
                      index,
                      itemSpec.key,
                      (event.target as HTMLTextAreaElement).value
                    )}
                  class="w-full px-2 py-1.5 bg-surface border border-line text-ink text-xs
                         resize-y focus:outline-none focus:border-accent"
                ></textarea>
              </div>
            {:else}
              <div class="mb-2">
                <span class="ng-label text-faint block mb-1">{labelFor(itemSpec)}</span>
                <input
                  value={String(item[itemSpec.key] ?? '')}
                  oninput={(event) =>
                    updateListItem(
                      spec.key,
                      index,
                      itemSpec.key,
                      (event.target as HTMLInputElement).value
                    )}
                  class="w-full h-9 px-2 bg-surface border border-line text-ink text-xs
                         focus:outline-none focus:border-accent"
                />
              </div>
            {/if}
          {/each}
        </div>
      {:else}
        <p class="text-xs text-faint">Пока пусто.</p>
      {/each}
    </div>
  {:else}
    <Field label={labelFor(spec)}>
      <input
        value={text(spec.key)}
        oninput={(event) => onchange(spec.key, (event.target as HTMLInputElement).value)}
        class="w-full h-10 px-3 bg-surface-2 border border-line text-ink text-sm
               focus:outline-none focus:border-accent transition-colors placeholder:text-faint"
      />
    </Field>
  {/if}
{/each}

<MediaPicker
  open={picking !== null}
  {siteId}
  onclose={() => (picking = null)}
  onpick={(item) => {
    if (!picking || !item.url) return;

    if (picking.index === null) {
      onchange(picking.key, item.url);
    } else {
      updateListItem(picking.key, picking.index, picking.itemKey ?? 'src', item.url);
    }
    picking = null;
  }}
/>
