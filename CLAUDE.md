# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Dockerator is a bash CLI tool (not an app you build/test) that orchestrates Docker Compose to manage multiple local dev projects (Next.js, WordPress, Vite+React, Parcel) behind Traefik, with shared MySQL/Adminer/Mailpit services and automatic `*.localhost` domain routing. The repo itself is the tool; `apps/` (git-ignored) holds the projects it scaffolds and manages.

## Commands

There is no build/lint/test suite — this is a shell script toolkit. To work on it:

```bash
./install.sh                       # symlinks `dockerator` to /usr/local/bin, sets up shell completion, copies docker-compose.yml.example -> docker-compose.yml
dockerator up / down                # start/stop shared services (Traefik, MySQL, Adminer, Mailpit)
dockerator new nextjs|wp|vite|parcel <name> [--with-db]   # scaffold a project
dockerator start|stop|restart <name>
dockerator dev-nextjs|dev-vite|dev-front|dev-wp <name>    # shells into the running container
dockerator list                     # scripts/list-projects.sh
dockerator logs [name]              # docker-compose logs -f
dockerator hosts                    # syncs *.localhost entries into /etc/hosts (needs sudo)
dockerator open <name>              # opens apps/<name> in VS Code
dockerator remove <name>            # stops container, removes from compose, deletes apps/<name>
```

Manually testing a change to a `scripts/*.sh` file means running the corresponding `dockerator <command>` against a scratch project in `apps/`.

## Architecture

**`dockerator`** is a thin dispatcher: it resolves its own real path (so it works via symlink from `/usr/local/bin`), `cd`s there, and routes `dockerator <command> ...` to a script in `scripts/`. Add new subcommands by adding a `case` branch here plus a new `scripts/<verb>-<noun>.sh`.

**`docker-compose.yml` is generated, not hand-edited.** `docker-compose.yml.example` is the checked-in template (defines `traefik`, `mysql`, `adminer`, `mailpit`); `docker-compose.yml` itself is git-ignored and is mutated in place by the `add-to-compose-*.sh` / `remove-from-compose.sh` scripts, which splice per-project service blocks in via a temp-file + marker-line insert (before the `volumes:` key). Never hand-edit `docker-compose.yml` — edit `.example` for template changes, or fix the generating script for structural changes.

**Two-phase project creation.** Each `new-<type>.sh` script (e.g. `new-nextjs.sh`) does host-side scaffolding — creates `apps/<name>`, copies `scripts/templates/<type>/*` in (Dockerfile, `.dockerignore`, framework files with `$APP_NAME`/`$SAFE_NAME` placeholders substituted via `sed`) — then calls the matching `add-to-compose-<type>.sh` to register the Traefik-routed service. Every step is idempotent/guarded (checks `[ -f ... ]` / `grep -q` before acting), so scripts are safe to re-run against a project that already partially exists — preserve that pattern in any new script.

**Name sanitization convention**, repeated across scripts: `SAFE_NAME`/`SAFE_URL` = lowercase, `_`→`-` (used for hostnames, container names, compose service keys); `SAFE_DB` = lowercase, `-`→`_` (used for MySQL db/user names). Both directions of translation appear depending on the script — check which one a given script uses before assuming.

**Existing-project detection (Next.js only).** `new-nextjs.sh` skips scaffolding entirely if `apps/<name>/src/app` already exists, so downloading a course repo into `apps/` and then running `dockerator new nextjs <name>` only adds Docker plumbing (Dockerfile, `.dockerignore`) without touching the app's own files or forcing TypeScript. New Next.js apps scaffolded from scratch always get TypeScript (`tsconfig.json`, `.tsx` files) from `scripts/templates/nextjs/`.

**Database wiring is opt-in for Next.js, automatic for WordPress.** Next.js only gets `DB_*` env vars + `depends_on: mysql (service_healthy)` in its compose block when `--with-db` is passed to `new nextjs` (threaded through to `add-to-compose-nextjs.sh`). WordPress (`new-wordpress.sh`) always provisions a MySQL database + user (named after `SAFE_DB`) directly via `docker exec dockerator_mysql mysql ...` and bakes credentials into `wp-config.php` from `scripts/templates/wordpress/wp-config.php.template`.

**Live-reload volume pattern.** Frontend project compose blocks bind-mount the whole app dir (`./apps/<name>:/app`) but use anonymous volumes to shadow `/app/node_modules` and `/app/.next` so the host's (possibly absent/stale) `node_modules` doesn't clobber the container's. This is why a plain restart doesn't pick up new dependencies — `scripts/restart-project.sh` exists specifically to `docker-compose build --no-cache` and `up --force-recreate --renew-anon-volumes`, discarding that anonymous volume so `npm install` reruns.

**Routing**: every project service gets Traefik labels (`traefik.http.routers.<name>.rule=Host(\`<name>.localhost\`)`); `scripts/sync-hosts.sh` greps all such labels out of `docker-compose.yml` and writes a single marked block into `/etc/hosts` (requires sudo, re-execs itself with `sudo` if needed).

## Conventions when adding/editing scripts

- `set -e` at the top of every script; colored output via the same `RED/GREEN/YELLOW/BLUE/NC` ANSI variable block copy-pasted per script.
- Every destructive or generative step is guarded and idempotent (see above) — don't add a step that fails on re-run against an already-scaffolded project.
- Container names are always `dockerator_<safe-name>`; compose service keys are always `<safe-name>` (hyphenated).
- New project types need: `scripts/new-<type>.sh`, `scripts/add-to-compose-<type>.sh`, a `scripts/templates/<type>/` directory, and a case branch in `dockerator`'s `new)` handler.
