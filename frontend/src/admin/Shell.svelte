<script lang="ts">
  import { router } from './lib/router.svelte';
  import { session } from './lib/session.svelte';
  import { appearance, ACCENTS } from './lib/theme.svelte';
  import { Icon } from './lib/ui';

  import Sites from './routes/Sites.svelte';
  import Pages from './routes/Pages.svelte';
  import Editor from './routes/Editor.svelte';
  import Domains from './routes/Domains.svelte';
  import Blocks from './routes/Blocks.svelte';
  import Media from './routes/Media.svelte';
  import Inbox from './routes/Inbox.svelte';
  import Account from './routes/Account.svelte';
  import SiteSettings from './routes/SiteSettings.svelte';

  const route = $derived(router.current);

  // The editor takes the whole window: a sidebar next to a page canvas leaves
  // too little room to judge how the page will actually look.
  const fullBleed = $derived(route.name === 'editor');

  const siteId = $derived('siteId' in route ? route.siteId : null);

  const sections = $derived(
    siteId
      ? [
          { name: 'pages', label: 'Страницы', icon: 'file', href: `/sites/${siteId}/pages` },
          { name: 'blocks', label: 'Блоки', icon: 'puzzle', href: `/sites/${siteId}/blocks` },
          { name: 'media', label: 'Файлы', icon: 'image', href: `/sites/${siteId}/media` },
          { name: 'domains', label: 'Домены', icon: 'globe', href: `/sites/${siteId}/domains` },
          { name: 'inbox', label: 'Заявки', icon: 'inbox', href: `/sites/${siteId}/inbox` },
          { name: 'site', label: 'Настройки', icon: 'settings', href: `/sites/${siteId}` }
        ]
      : []
  );

  function navigate(event: MouseEvent, href: string): void {
    event.preventDefault();
    router.go(href);
  }
</script>

{#if fullBleed}
  <Editor siteId={route.siteId} pageId={route.pageId} />
{:else}
  <div class="min-h-screen flex flex-col">
    <header class="flex items-center gap-4 px-4 sm:px-6 h-14 border-b border-line bg-surface">
      <a
        href="/"
        onclick={(event) => navigate(event, '/')}
        class="font-black tracking-tighter text-lg text-accent shrink-0"
      >
        Yulia
      </a>

      {#if sections.length}
        <nav class="flex items-center gap-1 overflow-x-auto">
          {#each sections as section (section.name)}
            <a
              href={section.href}
              onclick={(event) => navigate(event, section.href)}
              class="flex items-center gap-1.5 h-9 px-3 text-sm whitespace-nowrap transition-colors
                     {route.name === section.name
                ? 'bg-accent text-on-accent font-bold'
                : 'text-muted hover:text-ink hover:bg-surface-3'}"
            >
              <Icon name={section.icon} size={14} />
              {section.label}
            </a>
          {/each}
        </nav>
      {/if}

      <div class="flex-1"></div>

      <div class="flex items-center gap-1 shrink-0">
        <details class="relative">
          <summary
            class="list-none flex items-center justify-center w-9 h-9 text-muted hover:text-ink
                   hover:bg-surface-3 cursor-pointer transition-colors"
            title="Акцент"
          >
            <span class="w-4 h-4 border border-line-strong" style="background: var(--ng-accent)"
            ></span>
          </summary>
          <div class="absolute right-0 top-10 z-40 flex gap-1 p-2 bg-surface border border-line">
            {#each ACCENTS as accent (accent.id)}
              <button
                type="button"
                title={accent.label}
                onclick={() => appearance.setAccent(accent.id)}
                class="w-6 h-6 border-2 cursor-pointer transition-transform hover:scale-110
                       {appearance.accent === accent.id ? 'border-ink' : 'border-transparent'}"
                style="background: {accent.hex}"
                aria-label={accent.label}
              ></button>
            {/each}
          </div>
        </details>

        <button
          type="button"
          onclick={() => appearance.toggleTheme()}
          title={appearance.theme === 'dark' ? 'Светлая тема' : 'Тёмная тема'}
          class="flex items-center justify-center w-9 h-9 text-muted hover:text-ink
                 hover:bg-surface-3 cursor-pointer transition-colors"
        >
          <Icon name={appearance.theme === 'dark' ? 'sun' : 'moon'} size={16} />
        </button>

        <a
          href="/account"
          onclick={(event) => navigate(event, '/account')}
          title="Учётная запись"
          class="flex items-center justify-center w-9 h-9 transition-colors
                 {route.name === 'account'
            ? 'text-accent'
            : 'text-muted hover:text-ink hover:bg-surface-3'}"
        >
          <Icon name="shield" size={16} />
        </a>

        <button
          type="button"
          onclick={() => session.signOut()}
          title="Выйти"
          class="flex items-center justify-center w-9 h-9 text-muted hover:text-danger
                 cursor-pointer transition-colors"
        >
          <Icon name="logout" size={16} />
        </button>
      </div>
    </header>

    <main class="flex-1 px-4 sm:px-6 py-6 max-w-6xl w-full mx-auto">
      {#if route.name === 'sites'}
        <Sites />
      {:else if route.name === 'pages'}
        <Pages siteId={route.siteId} />
      {:else if route.name === 'site'}
        <SiteSettings siteId={route.siteId} />
      {:else if route.name === 'domains'}
        <Domains siteId={route.siteId} />
      {:else if route.name === 'blocks'}
        <Blocks siteId={route.siteId} />
      {:else if route.name === 'media'}
        <Media siteId={route.siteId} />
      {:else if route.name === 'inbox'}
        <Inbox siteId={route.siteId} />
      {:else if route.name === 'account'}
        <Account />
      {:else}
        <p class="text-muted text-sm">Такой страницы нет.</p>
      {/if}
    </main>
  </div>
{/if}
