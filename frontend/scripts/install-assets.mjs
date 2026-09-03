// Copies the built front end into the Rails public directory.
//
// Vite builds into frontend/dist so that the Docker image can copy a single
// self-contained directory. Locally the files still need to reach
// backend/public, which is where Rails serves them from; that is this script.

import { cp, rm, access } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const dist = resolve(here, '..', 'dist');
const publicDir = resolve(here, '..', '..', 'backend', 'public');

// Inside the container the Rails tree is not next to the front end, and the
// image copies the files itself. Nothing to do in that case.
try {
  await access(publicDir);
} catch {
  console.log('[yulia] backend/public not found - skipping asset install');
  process.exit(0);
}

for (const name of ['admin', 'yulia']) {
  const from = resolve(dist, name);
  const to = resolve(publicDir, name);

  // Removed first, so a file that no longer exists in the build does not linger
  // in the served directory.
  await rm(to, { recursive: true, force: true });
  await cp(from, to, { recursive: true });
  console.log(`[yulia] installed ${name} -> backend/public/${name}`);
}
