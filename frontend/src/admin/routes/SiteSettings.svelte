<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { router } from '../lib/router.svelte';
  import { Button, Card, Field, Input, Notice, Select } from '../lib/ui';
  import { ACCENTS } from '../lib/theme.svelte';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface NavLink {
    label: string;
    href: string;
  }

  interface Site {
    id: number;
    name: string;
    slug: string;
    locale: string;
    timezone: string;
    theme: string;
    accent: string;
    navigation: NavLink[];
  }

  let site = $state<Site | null>(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');

  $effect(() => {
    void siteId;
    loading = true;
    api
      .get<{ site: Site }>(`/api/sites/${siteId}`)
      .then((result) => (site = result.site))
      .catch((e) => (error = errorMessage(e)))
      .finally(() => (loading = false));
  });

  async function save(): Promise<void> {
    if (!site || saving) return;

    saving = true;
    error = '';
    notice = '';
    try {
      await api.patch(`/api/sites/${site.id}`, {
        site: {
          name: site.name,
          slug: site.slug,
          theme: site.theme,
          accent: site.accent,
          navigation: site.navigation
        }
      });
      notice = 'Сохранено.';
    } catch (e) {
      error = errorMessage(e);
    } finally {
      saving = false;
    }
  }

  async function destroy(): Promise<void> {
    if (!site) return;
    if (!confirm(`Удалить сайт «${site.name}» со всеми страницами? Это не отменить.`)) return;

    try {
      await api.delete(`/api/sites/${site.id}`);
      router.go('/');
    } catch (e) {
      error = errorMessage(e);
    }
  }

  function addLink(): void {
    if (!site) return;
    site.navigation = [...site.navigation, { label: '', href: '/' }];
  }

  function removeLink(index: number): void {
    if (!site) return;
    site.navigation = site.navigation.filter((_, position) => position !== index);
  }
</script>

<div class="mb-6">
  <h1 class="text-2xl font-black tracking-tight">Настройки сайта</h1>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}
{#if notice}
  <div class="mb-4"><Notice tone="success">{notice}</Notice></div>
{/if}

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if site}
  <div class="grid gap-4 lg:grid-cols-2">
    <Card title="Общее" accent>
      <Field label="Название">
        <Input bind:value={site.name} />
      </Field>
      <Field label="Служебный адрес" hint="Используется для предпросмотра: /preview/{site.slug}">
        <Input bind:value={site.slug} />
      </Field>
    </Card>

    <Card title="Оформление" accent>
      <Field label="Тема">
        <Select
          bind:value={site.theme}
          options={[
            { value: 'light', label: 'Светлая' },
            { value: 'dark', label: 'Тёмная' }
          ]}
        />
      </Field>

      <span class="ng-label text-muted block mb-1.5">Акцентный цвет</span>
      <div class="flex gap-2 flex-wrap">
        {#each ACCENTS as accent (accent.id)}
          <button
            type="button"
            title={accent.label}
            onclick={() => site && (site.accent = accent.id)}
            class="w-9 h-9 border-2 cursor-pointer transition-transform hover:scale-105
                   {site.accent === accent.id ? 'border-ink' : 'border-line'}"
            style="background: {accent.hex}"
            aria-label={accent.label}
          ></button>
        {/each}
      </div>
    </Card>

    <Card title="Меню сайта" subtitle="Ссылки в шапке" accent>
      {#each site.navigation as link, index (index)}
        <div class="flex gap-2 mb-2">
          <input
            bind:value={link.label}
            placeholder="Надпись"
            class="flex-1 h-9 px-2 bg-surface-2 border border-line text-sm
                   focus:outline-none focus:border-accent"
          />
          <input
            bind:value={link.href}
            placeholder="/адрес"
            class="flex-1 h-9 px-2 bg-surface-2 border border-line text-sm font-mono
                   focus:outline-none focus:border-accent"
          />
          <Button size="sm" variant="ghost" icon="trash" onclick={() => removeLink(index)} />
        </div>
      {/each}
      <Button size="sm" variant="outline" icon="plus" onclick={addLink}>Ссылка</Button>
    </Card>

    <Card title="Опасная зона">
      <p class="text-sm text-muted mb-4">
        Удаление сайта убирает все его страницы, файлы и заявки. Восстановить их будет нельзя.
      </p>
      <Button variant="danger" icon="trash" onclick={destroy}>Удалить сайт</Button>
    </Card>
  </div>

  <div class="mt-6">
    <Button icon="check" busy={saving} onclick={save}>Сохранить</Button>
  </div>
{/if}
