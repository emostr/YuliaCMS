// Drives the admin panel in a real browser.
//
// The API is covered by scripts/smoke.rb; what this adds is the one thing a
// request-level test cannot see - whether the Svelte application actually
// boots, renders and talks to that API through the proxy in front of it.
//
// It earned its place immediately: the admin panel could not write anything at
// all when reached on a non-standard port, because the Caddyfile overrode the
// Host header with a placeholder that drops the port, and Rails then rejected
// every request as a cross-origin forgery. Both the unit tests and the API
// smoke test passed throughout.
//
// Expects a stack with an empty database:
//
//   docker compose down && docker volume rm project-yulia_pgdata project-yulia_storage
//   docker compose up -d
//   npx playwright install chromium     # once
//   node scripts/browser-check.mjs
//
import { chromium } from 'playwright';

const BASE = process.env.YULIA_URL ?? 'http://localhost:8080';
const failures = [];
const problems = [];

function check(name, ok, detail) {
  console.log(`  ${ok ? 'ok   ' : 'FAIL '} ${name}${ok || !detail ? '' : ` — ${detail}`}`);
  if (!ok) failures.push(name);
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1400, height: 950 } });

// Anything the page logs as an error counts against it: a component that throws
// still leaves a shell behind, and the assertions alone would not notice.
page.on('console', (message) => {
  if (message.type() === 'error') problems.push(message.text());
});
page.on('pageerror', (error) => problems.push(String(error)));

console.log('\n1. The panel boots');
await page.goto(`${BASE}/`, { waitUntil: 'networkidle' });

const heading = await page.locator('h1').first().textContent();
check('setup screen rendered', /Создайте владельца/.test(heading ?? ''), heading);
check('Svelte mounted something', (await page.locator('#app *').count()) > 5);
check(
  'design tokens applied',
  await page.evaluate(() => getComputedStyle(document.body).backgroundColor !== 'rgba(0, 0, 0, 0)')
);

console.log('\n2. Validation answers as you type');
await page.getByRole('textbox').nth(2).fill('short');
await page.waitForTimeout(150);
check('short password is called out', await page.getByText('Пока слишком короткий.').isVisible());

console.log('\n3. Creating the owner');
const boxes = page.getByRole('textbox');
await boxes.nth(0).fill('Владелец');
await boxes.nth(1).fill('owner@example.com');
await boxes.nth(2).fill('correct horse battery staple');
await boxes.nth(3).fill('correct horse battery staple');
await page.getByRole('button', { name: /Создать и продолжить/ }).click();
await page.waitForTimeout(2500);

console.log('\n4. The second factor is demanded immediately');
const enrolHeading = await page.locator('h1').first().textContent();
check('enrolment screen shown', /Защитите вход/.test(enrolHeading ?? ''), enrolHeading);
check('QR rendered by the server', (await page.locator('svg').count()) > 0);
check(
  'manual entry offered as a fallback',
  await page.getByText('Не получается отсканировать?').isVisible()
);

console.log('\n5. Nothing threw');
check('no console errors', problems.length === 0, problems.slice(0, 3).join(' | '));

await browser.close();

console.log('\n' + '-'.repeat(58));
if (failures.length === 0) {
  console.log('BROWSER: everything passed');
} else {
  console.log(`BROWSER: ${failures.length} failed`);
  process.exit(1);
}
