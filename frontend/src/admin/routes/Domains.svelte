<script lang="ts">
  import { api, errorMessage } from '../lib/api';
  import { Badge, Button, EmptyState, Field, Icon, Input, Notice } from '../lib/ui';

  interface Props {
    siteId: number;
  }

  let { siteId }: Props = $props();

  interface Dns {
    ok: boolean;
    addresses: string[];
    expected: string | null;
    error: string | null;
  }

  interface Domain {
    id: number;
    host: string;
    primary: boolean;
    certified: boolean;
    dns?: Dns;
  }

  let domains = $state<Domain[]>([]);
  let loading = $state(true);
  let error = $state('');
  let host = $state('');
  let busy = $state(false);

  async function load(): Promise<void> {
    loading = true;
    try {
      domains = (await api.get<{ domains: Domain[] }>(`/api/sites/${siteId}/domains`)).domains;
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

  async function add(event: Event): Promise<void> {
    event.preventDefault();
    if (busy || host.trim() === '') return;

    busy = true;
    error = '';
    try {
      const result = await api.post<{ domain: Domain }>(`/api/sites/${siteId}/domains`, {
        domain: { host: host.trim() }
      });
      domains = [...domains, result.domain];
      host = '';
    } catch (e) {
      error = errorMessage(e);
    } finally {
      busy = false;
    }
  }

  async function makePrimary(domain: Domain): Promise<void> {
    try {
      await api.post(`/api/domains/${domain.id}/primary`);
      domains = domains.map((candidate) => ({
        ...candidate,
        primary: candidate.id === domain.id
      }));
    } catch (e) {
      error = errorMessage(e);
    }
  }

  async function remove(domain: Domain): Promise<void> {
    if (!confirm(`Отвязать домен ${domain.host}?`)) return;

    try {
      await api.delete(`/api/domains/${domain.id}`);
      domains = domains.filter((candidate) => candidate.id !== domain.id);
    } catch (e) {
      error = errorMessage(e);
    }
  }

  // The DNS answer is the thing people get wrong, so it is spelled out rather
  // than reduced to a red dot.
  function dnsMessage(dns: Dns): string {
    if (dns.ok) return 'DNS настроен верно.';

    switch (dns.error) {
      case 'no_record':
        return 'У домена нет A-записи. Добавьте её у регистратора и подождите — обновление занимает до нескольких часов.';
      case 'points_elsewhere':
        return `Домен указывает на ${dns.addresses.join(', ')}, а нужно на ${dns.expected}.`;
      case 'unknown_server_ip':
        return 'Не удалось выяснить внешний адрес сервера, поэтому проверить некуда. Домен всё равно добавлен.';
      default:
        return 'Проверить DNS не получилось.';
    }
  }
</script>

<div class="mb-6">
  <h1 class="text-2xl font-black tracking-tight">Домены</h1>
  <p class="text-sm text-muted">
    Направьте домен A-записью на этот сервер и добавьте его здесь. Сертификат Yulia выпустит сама.
  </p>
</div>

{#if error}
  <div class="mb-4"><Notice tone="danger">{error}</Notice></div>
{/if}

<form onsubmit={add} class="flex gap-2 items-end mb-6 max-w-lg">
  <div class="flex-1">
    <Field label="Новый домен">
      <Input bind:value={host} placeholder="example.com" />
    </Field>
  </div>
  <div class="mb-4">
    <Button type="submit" icon="plus" {busy} disabled={host.trim() === ''}>Добавить</Button>
  </div>
</form>

{#if loading}
  <p class="text-sm text-muted">Загрузка…</p>
{:else if domains.length === 0}
  <div class="bg-surface border border-line">
    <EmptyState
      icon="globe"
      title="Домены не привязаны"
      text="Пока сайт открывается только по служебному адресу предпросмотра."
    />
  </div>
{:else}
  <div class="bg-surface border border-line divide-y divide-line">
    {#each domains as domain (domain.id)}
      <div class="px-5 py-4">
        <div class="flex items-center gap-3">
          <span class="text-accent"><Icon name="globe" size={16} /></span>
          <span class="font-bold font-mono text-sm flex-1 truncate">{domain.host}</span>

          {#if domain.primary}
            <Badge tone="accent">основной</Badge>
          {/if}
          {#if domain.certified}
            <Badge tone="success">сертификат выдан</Badge>
          {:else}
            <Badge tone="warning">ждёт сертификата</Badge>
          {/if}

          {#if !domain.primary}
            <Button size="sm" variant="ghost" onclick={() => makePrimary(domain)}>
              Сделать основным
            </Button>
          {/if}
          <Button
            size="sm"
            variant="ghost"
            icon="trash"
            title="Отвязать"
            onclick={() => remove(domain)}
          />
        </div>

        {#if domain.dns}
          <div class="mt-3">
            <Notice tone={domain.dns.ok ? 'success' : 'warning'}>{dnsMessage(domain.dns)}</Notice>
          </div>
        {/if}
      </div>
    {/each}
  </div>
{/if}
