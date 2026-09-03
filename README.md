# Yulia CMS

**Простая CMS, которую ставят одной командой и дальше не трогают сервер.**
*A small CMS you install with one command and then never touch the server again.*

[Документация](https://emostr.github.io/YuliaCMS/ru/install/) · [Documentation](https://emostr.github.io/YuliaCMS/en/install/)

---

## Русский

Yulia — это то, чем мог бы быть WordPress, если бы его писали сегодня: визуальный
редактор, понятный без обучения, установка одной командой и сервер, на который
не нужно возвращаться.

### Что она делает

- **Визуальный редактор.** Страница собирается из блоков: обложка, текст, галерея,
  форма. Порядок меняется перетаскиванием, настройки — в панели рядом.
- **Богатый текст с LaTeX.** Заголовки, списки, цитаты, картинки и формулы прямо
  в тексте, с предпросмотром и сотней заготовок.
- **Черновик и публикация.** Посетитель видит опубликованную версию, пока вы не
  нажали «Опубликовать».
- **Много сайтов на одной установке.** У каждого свой домен и свой сертификат.
- **HTTPS сам.** Направьте домен на сервер, впишите его в админке — сертификат
  Let's Encrypt выпустится при первом обращении.
- **Свои блоки.** Не хватило готовых — напишите свой на Liquid с
  [htmx](https://emostr.github.io/YuliaCMS/ru/htmx/) или компонентом Svelte. Прямо
  в админке, без доступа к серверу.

### Почему сайты получаются быстрыми

Один путь рендеринга: страницу собирает сервер, браузер получает готовый HTML.
Скрипты подключаются только там, где нужны — страница из текста и картинок не
грузит ни байта JavaScript. htmx добавляется, если на странице есть форма или ваш
блок с `hx-`-атрибутами. Компонент Svelte становится островом и загружается
только на тех страницах, где стоит.

### Установка

На чистом Debian 13:

```bash
apt-get update && apt-get install -y ruby curl
curl -fsSL https://raw.githubusercontent.com/emostr/YuliaCMS/main/InstallYulia.rb -o InstallYulia.rb
sudo ruby InstallYulia.rb
```

Скрипт спросит домен админки, проверит его по DNS, поставит Docker, скачает Yulia
и всё запустит. Повторный запуск обновляет установку.

Подробно, включая установку самого Debian: [документация](https://emostr.github.io/YuliaCMS/ru/install/).

### Попробовать локально

```bash
git clone https://github.com/emostr/YuliaCMS.git
cd yulia
cp .env.example .env
sed -i '' "s/^SECRET_KEY_BASE=$/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env
docker compose up -d --build
```

Админка — `http://localhost:8080`.

---

## English

Yulia is what WordPress might be if it were written today: a visual editor that
needs no training, an install that takes one command, and a server you never have
to go back to.

### What it does

- **A visual editor.** Pages are built from blocks — hero, text, gallery, form.
  Reorder by dragging; configure in the panel beside it.
- **Rich text with LaTeX.** Headings, lists, quotes, pictures and formulas inline,
  with a live preview and a hundred ready-made fragments.
- **Drafts and publishing.** Visitors see the published version until you press
  Publish.
- **Many sites per installation.** Each with its own domain and certificate.
- **HTTPS by itself.** Point a domain at the server, type it into the admin panel,
  and the Let's Encrypt certificate is obtained on the first request.
- **Your own blocks.** When the built-in ones are not enough, write one in Liquid
  with [htmx](https://emostr.github.io/YuliaCMS/en/htmx/), or as a Svelte component —
  from the admin panel, with no server access.

### Why the sites come out fast

One rendering path: the server assembles the page and the browser receives
finished HTML. Scripts load only where they are needed, so a page of text and
pictures ships no JavaScript at all. htmx is added when a page carries a form or
one of your blocks using `hx-` attributes. A Svelte component becomes an island,
loaded only on the pages that place it.

### Installing

On a fresh Debian 13:

```bash
apt-get update && apt-get install -y ruby curl
curl -fsSL https://raw.githubusercontent.com/emostr/YuliaCMS/main/InstallYulia.rb -o InstallYulia.rb
sudo ruby InstallYulia.rb
```

The script asks for the admin panel's domain, checks it against DNS, installs
Docker, downloads Yulia and starts everything. Running it again updates the
installation.

Full instructions, including installing Debian itself:
[documentation](https://emostr.github.io/YuliaCMS/en/install/).

### Running it locally

```bash
git clone https://github.com/emostr/YuliaCMS.git
cd yulia
cp .env.example .env
sed -i '' "s/^SECRET_KEY_BASE=$/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env
docker compose up -d --build
```

The admin panel opens at `http://localhost:8080`.

---

## Стек / Stack

| | |
|---|---|
| Бэкенд / Backend | Ruby 4.0, Rails 8.1, Solid Queue/Cache/Cable |
| СУБД / Database | PostgreSQL 18 |
| Админка / Admin panel | Svelte 5, Vite 8, Tailwind 4, TipTap 3, KaTeX |
| Публичные сайты / Public sites | Ruby → HTML, htmx 4, Svelte islands |
| Шаблоны блоков / Block templates | Liquid |
| Веб-сервер / Web server | Caddy 2 with on-demand TLS |
| Запуск / Runtime | Docker Compose |

## Устройство репозитория / Repository layout

```
backend/          Rails: models, admin API, public renderer, Liquid blocks
  app/blocks/     built-in block templates — worked examples for your own
frontend/
  src/admin/      the admin panel (Svelte)
  src/site/       what a published site loads: htmx, island loader, stylesheet
  scripts/        island builder, run on the server
caddy/            Caddyfile for a server, and one for your own machine
docs/             this documentation, published to GitHub Pages
InstallYulia.rb   the installer
```

## Разработка / Development

```bash
docker compose up -d postgres

cd backend && bundle install
POSTGRES_DB=yulia_development bin/rails db:prepare
POSTGRES_DB=yulia_development bin/rails server -p 3111

cd frontend && npm install && npm run build   # or: npm run dev
```

Тесты / Tests:

```bash
cd backend && RAILS_ENV=test bin/rails test
```

## Лицензия / Licence

Apache License 2.0. See [LICENSE](LICENSE).
