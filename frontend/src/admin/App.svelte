<script lang="ts">
  import { session } from './lib/session.svelte';
  import Shell from './Shell.svelte';
  import Setup from './routes/Setup.svelte';
  import SignIn from './routes/SignIn.svelte';
  import SecondFactor from './routes/SecondFactor.svelte';
  import Enrol from './routes/Enrol.svelte';
  import { Notice } from './lib/ui';

  let failure = $state('');

  // One load decides which of the five states the panel opens in: needs
  // installing, signed out, mid-sign-in, needs a second factor, or ready.
  $effect(() => {
    session.load().catch(() => {
      failure = 'Не удалось связаться с сервером Yulia. Он запущен?';
    });
  });
</script>

{#if failure}
  <div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-md">
      <Notice tone="danger">{failure}</Notice>
    </div>
  </div>
{:else if session.stage === 'loading'}
  <div class="min-h-screen flex items-center justify-center text-muted text-sm">Загрузка…</div>
{:else if session.stage === 'setup'}
  <Setup />
{:else if session.stage === 'signed-out'}
  <SignIn />
{:else if session.stage === 'second-factor'}
  <SecondFactor />
{:else if session.stage === 'enrol'}
  <Enrol />
{:else}
  <Shell />
{/if}
