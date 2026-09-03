# syntax=docker/dockerfile:1

# Yulia CMS - one image holding the Rails application, the compiled admin panel
# and the public-site runtime.
#
# Debian rather than Alpine, to match the operating system the installation
# guide asks people to put on their server: when something goes wrong, the
# commands in the guide and the commands inside the container are the same ones.

ARG RUBY_VERSION=4.0.5
ARG NODE_VERSION=26

# --- Stage 1: build the front end -------------------------------------------
#
# The admin panel (Svelte) and the site runtime (htmx, islands, stylesheet) are
# compiled here and copied into the runtime image as static files. No Node
# process serves them at run time.

FROM node:${NODE_VERSION}-trixie-slim AS frontend

WORKDIR /build

# Dependencies are installed from the lockfile alone, so this layer is reused
# whenever only application code has changed.
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build


# --- Stage 2: tools for compiling user blocks --------------------------------
#
# The runtime needs a Svelte compiler so that a block written in the admin panel
# can be built without anyone touching the server. It does not need TypeScript,
# TipTap or KaTeX, which are build-time only - installing just the three
# packages build-island.mjs imports keeps roughly 60 MB out of the final image.
#
# Versions are read from frontend/package.json so they cannot drift from the
# ones the admin panel was built with.

FROM node:${NODE_VERSION}-trixie-slim AS islandtools

WORKDIR /tools

COPY frontend/package.json ./source-package.json
RUN node -e "\
      const pkg = require('./source-package.json'); \
      const all = { ...pkg.dependencies, ...pkg.devDependencies }; \
      const needed = ['vite', '@sveltejs/vite-plugin-svelte', 'svelte']; \
      const missing = needed.filter((name) => !all[name]); \
      if (missing.length) throw new Error('missing from package.json: ' + missing); \
      require('fs').writeFileSync('install.txt', needed.map((n) => n + '@' + all[n]).join(' ')); \
    " && \
    npm init --yes > /dev/null && \
    npm install --no-audit --no-fund $(cat install.txt) && \
    npm cache clean --force


# --- Stage 3: install gems ---------------------------------------------------

FROM ruby:${RUBY_VERSION}-slim-trixie AS gems

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# BUNDLE_PATH must match the runtime stage exactly. Without it, bundler installs
# into the system gem layout here and looks in the BUNDLE_PATH layout there, and
# the container starts up unable to find a single gem.
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install --jobs 4 && \
    # Bundled git checkouts keep their history, which is dead weight in an image.
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git


# --- Stage 4: the image that runs ---------------------------------------------

FROM ruby:${RUBY_VERSION}-slim-trixie AS runtime

# libpq5  - PostgreSQL client library for the pg gem
# libvips - image processing for uploaded pictures
# curl    - used by the container health check
# nodejs  - compiles user-written Svelte blocks *on the server*, which is what
#           lets somebody add a block from the admin panel without ever opening
#           a terminal again
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libpq5 libvips42 libyaml-0-2 nodejs ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=true \
    RUBY_YJIT_ENABLE=1

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY backend/ ./

# Compiled front end. The admin panel is served from public/admin, the site
# runtime from public/yulia.
COPY --from=frontend /build/dist/admin ./public/admin
COPY --from=frontend /build/dist/yulia ./public/yulia

# The island builder is invoked by CompileIslandJob at run time.
COPY frontend/scripts ./frontend/scripts
COPY frontend/package.json ./frontend/package.json
COPY --from=islandtools /tools/node_modules ./frontend/node_modules

# Bootsnap caches are compiled once here rather than on every boot.
RUN SECRET_KEY_BASE=placeholder ./bin/rails runner "puts 'boot check passed'" || true

# The application must not run as root: a flaw in a dependency should not hand
# over the container.
RUN groupadd --system --gid 1000 yulia && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash yulia && \
    mkdir -p storage tmp log && \
    chown -R yulia:yulia /rails
USER yulia:yulia

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
