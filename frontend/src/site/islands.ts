// Boots the Svelte islands a page happens to contain.
//
// A page with no island never loads this file, and a page with two islands
// loads two small bundles rather than a framework runtime for the whole site.
// Each island bundle registers itself here by calling window.yuliaIsland.

type Mounter = (target: Element, props: Record<string, unknown>) => void;

declare global {
  interface Window {
    yuliaIsland?: (key: string, mount: Mounter) => void;
  }
}

const pending = new Map<string, Element[]>();
const mounters = new Map<string, Mounter>();

function propsFor(element: Element): Record<string, unknown> {
  const raw = element.getAttribute('data-yulia-props');
  if (!raw) return {};

  try {
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    // A malformed payload should cost one block, not the page.
    console.warn('[yulia] island props could not be parsed', element);
    return {};
  }
}

function mount(key: string, element: Element): void {
  const mounter = mounters.get(key);
  if (!mounter) {
    // The bundle has not arrived yet; it will drain this queue when it does.
    const queue = pending.get(key) ?? [];
    queue.push(element);
    pending.set(key, queue);
    return;
  }

  try {
    mounter(element, propsFor(element));
  } catch (error) {
    console.error(`[yulia] island "${key}" failed to mount`, error);
  }
}

window.yuliaIsland = (key, mounter) => {
  mounters.set(key, mounter);
  const queue = pending.get(key);
  if (queue) {
    queue.forEach((element) => mount(key, element));
    pending.delete(key);
  }
};

function scan(root: ParentNode = document): void {
  root.querySelectorAll<HTMLElement>('[data-yulia-island]').forEach((element) => {
    if (element.dataset.yuliaMounted === 'true') return;
    element.dataset.yuliaMounted = 'true';
    mount(element.dataset.yuliaIsland as string, element);
  });
}

// An island bundle can finish loading before this bootstrapper does. Those
// register themselves into a queue, which is drained here.
const queued = (window as unknown as { __yuliaPendingIslands?: [string, Mounter][] })
  .__yuliaPendingIslands;
if (queued) {
  queued.forEach(([key, mounter]) => window.yuliaIsland?.(key, mounter));
  delete (window as unknown as { __yuliaPendingIslands?: unknown }).__yuliaPendingIslands;
}

scan();

// Content swapped in by htmx can carry islands of its own. In htmx 4 the event
// is colon-separated - htmx:after:swap, not htmx:afterSwap.
document.addEventListener('htmx:after:swap', (event) => {
  const target = (event as CustomEvent).detail?.target ?? document;
  scan(target as ParentNode);
});
