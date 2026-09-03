<script lang="ts">
  import { onDestroy } from 'svelte';
  import { Editor } from '@tiptap/core';
  import StarterKit from '@tiptap/starter-kit';
  import Image from '@tiptap/extension-image';
  import katex from 'katex';
  import 'katex/dist/katex.min.css';

  import { MathInline } from './MathNode';
  import { FORMULA_GROUPS } from './formulas';
  import { Button, Field, Icon, Input, Modal, Textarea } from '../ui';

  interface Props {
    value: string;
    placeholder?: string;
    onchange: (html: string) => void;
  }

  let { value, placeholder = 'Текст…', onchange }: Props = $props();

  let host = $state<HTMLDivElement | null>(null);
  let editor = $state<Editor | null>(null);

  // Re-read on every keystroke so the toolbar can show what is active at the
  // cursor. Svelte only re-renders the buttons that actually changed.
  let tick = $state(0);

  let formulaOpen = $state(false);
  let formula = $state('');
  let search = $state('');
  let editingFormula = $state(false);
  let formulaField = $state<HTMLTextAreaElement | null>(null);

  $effect(() => {
    if (!host || editor) return;

    const instance = new Editor({
      element: host,
      extensions: [
        StarterKit.configure({ heading: { levels: [2, 3] } }),
        Image.configure({ inline: false, allowBase64: false }),
        MathInline
      ],
      content: value || '',
      editorProps: {
        attributes: {
          class: 'px-3 py-2.5 text-sm text-ink outline-none',
          'data-placeholder': placeholder
        }
      },
      onUpdate: ({ editor: current }) => onchange(current.getHTML()),
      onSelectionUpdate: () => (tick += 1),
      onTransaction: () => (tick += 1)
    });

    editor = instance;
  });

  // A value replaced from outside - switching to another block, undoing - has
  // to reach the editor, but resetting it while somebody is typing would throw
  // the cursor to the start of the line.
  $effect(() => {
    const current = editor;
    if (current && value !== current.getHTML()) {
      current.commands.setContent(value || '', { emitUpdate: false });
    }
  });

  onDestroy(() => editor?.destroy());

  function openFormula(): void {
    if (!editor) return;

    const active = editor.isActive('formula');
    editingFormula = active;
    formula = active ? String(editor.getAttributes('formula').latex ?? '') : '';
    search = '';
    formulaOpen = true;
  }

  function applyFormula(): void {
    if (!editor || !formula.trim()) return;

    if (editingFormula) {
      editor.chain().focus().updateFormula(formula).run();
    } else {
      editor.chain().focus().insertFormula(formula).run();
    }
    formulaOpen = false;
    formula = '';
  }

  // Inserted where the caret sits, not appended: otherwise a power cannot be
  // added inside a fraction that is already half typed.
  function insertSnippet(latex: string): void {
    const field = formulaField;
    if (!field) {
      formula = formula ? `${formula} ${latex}` : latex;
      return;
    }

    const start = field.selectionStart ?? formula.length;
    const end = field.selectionEnd ?? formula.length;
    formula = `${formula.slice(0, start)}${latex}${formula.slice(end)}`;

    requestAnimationFrame(() => {
      field.focus();
      const caret = start + latex.length;
      field.setSelectionRange(caret, caret);
    });
  }

  const preview = $derived.by(() => {
    if (!formula.trim()) return '';

    try {
      return katex.renderToString(formula, {
        throwOnError: false,
        displayMode: true,
        output: 'html'
      });
    } catch {
      return `<span style="color:var(--ng-danger)">${formula}</span>`;
    }
  });

  const groups = $derived.by(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return FORMULA_GROUPS;

    return FORMULA_GROUPS.map((group) => ({
      title: group.title,
      items: group.items.filter(
        (item) =>
          item.label.toLowerCase().includes(needle) || item.latex.toLowerCase().includes(needle)
      )
    })).filter((group) => group.items.length > 0);
  });

  interface ToolButton {
    icon: string;
    title: string;
    run: () => void;
    active?: () => boolean;
  }

  const tools = $derived.by<ToolButton[]>(() => {
    const current = editor;
    if (!current) return [];

    return [
      {
        icon: 'bold',
        title: 'Полужирный',
        run: () => current.chain().focus().toggleBold().run(),
        active: () => current.isActive('bold')
      },
      {
        icon: 'italic',
        title: 'Курсив',
        run: () => current.chain().focus().toggleItalic().run(),
        active: () => current.isActive('italic')
      },
      {
        icon: 'heading',
        title: 'Подзаголовок',
        run: () => current.chain().focus().toggleHeading({ level: 2 }).run(),
        active: () => current.isActive('heading', { level: 2 })
      },
      {
        icon: 'list',
        title: 'Список',
        run: () => current.chain().focus().toggleBulletList().run(),
        active: () => current.isActive('bulletList')
      },
      {
        icon: 'listOrdered',
        title: 'Нумерованный список',
        run: () => current.chain().focus().toggleOrderedList().run(),
        active: () => current.isActive('orderedList')
      },
      {
        icon: 'quote',
        title: 'Цитата',
        run: () => current.chain().focus().toggleBlockquote().run(),
        active: () => current.isActive('blockquote')
      },
      {
        icon: 'code',
        title: 'Код',
        run: () => current.chain().focus().toggleCode().run(),
        active: () => current.isActive('code')
      }
    ];
  });
</script>

<div class="border border-line bg-surface-2 focus-within:border-accent transition-colors">
  <div class="flex flex-wrap items-center gap-0.5 px-1.5 py-1 border-b border-line bg-surface">
    {#key tick}
      {#each tools as tool (tool.title)}
        <button
          type="button"
          title={tool.title}
          onclick={tool.run}
          class="h-8 w-8 flex items-center justify-center transition-colors cursor-pointer
                 {tool.active?.()
            ? 'bg-accent text-on-accent'
            : 'text-muted hover:text-ink hover:bg-surface-3'}"
        >
          <Icon name={tool.icon} size={15} />
        </button>
      {/each}

      <span class="w-px h-5 bg-line mx-1"></span>

      <button
        type="button"
        title="Формула (LaTeX)"
        onclick={openFormula}
        class="h-8 w-8 flex items-center justify-center transition-colors cursor-pointer
               {editor?.isActive('formula')
          ? 'bg-accent text-on-accent'
          : 'text-muted hover:text-ink hover:bg-surface-3'}"
      >
        <Icon name="sigma" size={15} />
      </button>

      <span class="flex-1"></span>

      <button
        type="button"
        title="Убрать форматирование"
        onclick={() => editor?.chain().focus().unsetAllMarks().clearNodes().run()}
        class="h-8 w-8 flex items-center justify-center text-muted hover:text-ink
               hover:bg-surface-3 transition-colors cursor-pointer"
      >
        <Icon name="refresh" size={15} />
      </button>
    {/key}
  </div>

  <div bind:this={host}></div>
</div>

<Modal
  open={formulaOpen}
  title={editingFormula ? 'Правка формулы' : 'Формула'}
  subtitle="Синтаксис LaTeX — как в учебнике"
  size="xl"
  onclose={() => (formulaOpen = false)}
>
  <div class="grid gap-5 lg:grid-cols-2">
    <div>
      <Field label="Формула">
        <textarea
          bind:this={formulaField}
          bind:value={formula}
          rows="4"
          placeholder={'\\frac{1}{2} + \\sqrt{x}'}
          class="w-full px-3 py-2 bg-surface-2 border border-line text-ink text-sm font-mono
                 resize-y focus:outline-none focus:border-accent transition-colors"
        ></textarea>
      </Field>

      <div class="ng-label text-muted mb-2">Предпросмотр</div>
      <div
        class="border border-line bg-surface px-4 py-5 text-center min-h-[84px] flex
               items-center justify-center overflow-x-auto"
      >
        {#if preview}
          {@html preview}
        {:else}
          <span class="text-faint text-xs">Здесь появится формула</span>
        {/if}
      </div>
    </div>

    <div class="min-w-0">
      <Field label="Заготовки">
        <Input bind:value={search} placeholder="дробь, корень, вектор…" />
      </Field>

      {#if groups.length === 0}
        <p class="text-sm text-muted">Ничего не нашлось — наберите формулу вручную.</p>
      {:else}
        <div class="max-h-[420px] overflow-y-auto pr-1 space-y-4">
          {#each groups as group (group.title)}
            <div>
              <div class="ng-label text-faint mb-1.5">{group.title}</div>
              <div class="flex flex-wrap gap-1.5">
                {#each group.items as item (item.label)}
                  <button
                    type="button"
                    title={item.latex}
                    onclick={() => insertSnippet(item.latex)}
                    class="px-2.5 py-1 text-xs border border-line bg-surface hover:border-accent
                           hover:text-accent transition-colors cursor-pointer"
                  >
                    {item.label}
                  </button>
                {/each}
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>

  {#snippet footer()}
    <Button variant="ghost" onclick={() => (formulaOpen = false)}>Отмена</Button>
    <Button icon="check" onclick={applyFormula} disabled={!formula.trim()}>
      {editingFormula ? 'Сохранить' : 'Вставить'}
    </Button>
  {/snippet}
</Modal>
