// A router small enough to read in one sitting.
//
// The panel has a handful of screens, so a routing library would be more code
// than the thing it routes. Paths are matched with plain patterns and the
// browser's history API does the rest.

export type Route =
  | { name: 'sites' }
  | { name: 'site'; siteId: number }
  | { name: 'pages'; siteId: number }
  | { name: 'editor'; siteId: number; pageId: number }
  | { name: 'blocks'; siteId: number }
  | { name: 'media'; siteId: number }
  | { name: 'domains'; siteId: number }
  | { name: 'inbox'; siteId: number }
  | { name: 'account' }
  | { name: 'unknown' };

function parse(pathname: string): Route {
  const parts = pathname.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);

  if (parts.length === 0) return { name: 'sites' };
  if (parts[0] === 'account') return { name: 'account' };

  if (parts[0] === 'sites' && parts[1]) {
    const siteId = Number(parts[1]);
    if (Number.isNaN(siteId)) return { name: 'unknown' };

    const section = parts[2];
    if (!section) return { name: 'site', siteId };
    if (section === 'pages' && parts[3]) {
      const pageId = Number(parts[3]);
      return Number.isNaN(pageId) ? { name: 'unknown' } : { name: 'editor', siteId, pageId };
    }
    if (section === 'pages') return { name: 'pages', siteId };
    if (section === 'blocks') return { name: 'blocks', siteId };
    if (section === 'media') return { name: 'media', siteId };
    if (section === 'domains') return { name: 'domains', siteId };
    if (section === 'inbox') return { name: 'inbox', siteId };
  }

  return { name: 'unknown' };
}

class Router {
  current = $state<Route>(parse(location.pathname));

  start(): void {
    window.addEventListener('popstate', () => {
      this.current = parse(location.pathname);
    });
  }

  go(path: string): void {
    if (path === location.pathname) return;

    history.pushState({}, '', path);
    this.current = parse(path);
    // A new screen starts at the top, the way a page load would.
    window.scrollTo({ top: 0 });
  }

  replace(path: string): void {
    history.replaceState({}, '', path);
    this.current = parse(path);
  }
}

export const router = new Router();
