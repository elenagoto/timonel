# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Dockerator is a bash CLI tool (not an app you build/test) that orchestrates Docker Compose to manage multiple local dev projects (Next.js, WordPress, Vite+React, Parcel) behind Traefik, with shared MySQL/Adminer/Mailpit services and automatic `*.localhost` domain routing. The repo itself is the tool; `apps/` (git-ignored) holds the projects it scaffolds and manages.

**Ongoing redesign:** the tool is being restructured (node/php stacks, `new` vs `add`, a single `dev`) and renamed to **timonel**. The plan and progress are in [ROADMAP.md](ROADMAP.md). Read it before starting work, and tick items off there.

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

**`docker-compose.yml` is generated, not hand-edited.** `docker-compose.yml.example` is the checked-in template (defines `traefik`, `mysql`, `adminer`, `mailpit`); `docker-compose.yml` itself is git-ignored and is mutated in place by `add-to-compose.sh` (Node projects), `add-to-compose-wp.sh` and `remove-from-compose.sh`, which splice per-project service blocks in with `insert_service_block` from `scripts/lib/compose.sh` (before the first top-level `volumes:`/`networks:` key). Read project services with `list_project_services` / `project_service_exists` / `service_label` from the same file, not `grep "^  name:"` (that also matches network and volume keys). Never hand-edit `docker-compose.yml` — edit `.example` for template changes, or fix the generating script for structural changes.

**Two-phase project creation.** Each `new-<type>.sh` script (e.g. `new-nextjs.sh`) does host-side scaffolding — creates `apps/<name>`, copies framework files from `scripts/templates/<type>/` (with `$APP_NAME`/`$SAFE_NAME` placeholders substituted via `sed`) — then registers the Traefik-routed service. Node projects (Next.js, Vite, Parcel) all get the same `Dockerfile` + `.dockerignore` from `scripts/templates/stacks/node/` and are registered by `add-to-compose.sh <name> <framework> [--with-db]`; WordPress still has its own `add-to-compose-wp.sh`.

**Framework settings live in one table.** `scripts/lib/frameworks.sh` (`framework_setting <framework> <key>`, a `case` function because macOS bash 3.2 has no associative arrays) holds each framework's stack, port, cache volumes, extra dev-server args and display name. `add-to-compose.sh` builds the compose block from it and labels it `dockerator.stack=<stack>` / `dockerator.framework=<framework>`; `list` reads the framework label (falling back to file-based guessing for unlabelled projects). Every step is idempotent/guarded (checks `[ -f ... ]` / `grep -q` before acting), so scripts are safe to re-run against a project that already partially exists — preserve that pattern in any new script.

**Name sanitization convention**, repeated across scripts: `SAFE_NAME`/`SAFE_URL` = lowercase, `_`→`-` (used for hostnames, container names, compose service keys); `SAFE_DB` = lowercase, `-`→`_` (used for MySQL db/user names). Both directions of translation appear depending on the script — check which one a given script uses before assuming. The `apps/` folder keeps the name *as typed* (e.g. `my_app`), so it can differ from the service key (`my-app`): never build `apps/$SAFE_NAME` — use `resolve_app_dir_name` from `scripts/lib/project.sh` (sourced, not executed), which reads the folder from the service's `build.context`. The dispatcher validates every project-name argument (`is_valid_project_name`: `[A-Za-z0-9][A-Za-z0-9_-]*`) and rejects core-service names for `new`/`remove`.

**Existing-project detection (Next.js only).** `new-nextjs.sh` skips scaffolding entirely if `apps/<name>/src/app` already exists, so downloading a course repo into `apps/` and then running `dockerator new nextjs <name>` only adds Docker plumbing (Dockerfile, `.dockerignore`) without touching the app's own files or forcing TypeScript. New Next.js apps scaffolded from scratch always get TypeScript (`tsconfig.json`, `.tsx` files) from `scripts/templates/nextjs/`.

**Database wiring is opt-in for Node projects, automatic for WordPress.** Next.js, Vite and Parcel projects only get `DB_*` env vars + `depends_on: mysql (service_healthy)` in their compose block when `--with-db` is passed to `new` (threaded through to `add-to-compose.sh`; the dispatcher rejects any other flag). WordPress (`new-wordpress.sh`) always provisions a database. WordPress and `--with-db` Node projects both go through `scripts/create-db.sh <safe_db>`, which starts MySQL if needed (`up -d --wait mysql`) and idempotently creates the database + user (name = user = password). WordPress bakes the credentials into `wp-config.php` from `scripts/templates/wordpress/wp-config.php.template`, and gets a `wp-content/mu-plugins/dockerator-mailpit.php` that routes `wp_mail` to Mailpit.

**WordPress dev mode doesn't edit `docker-compose.yml`.** WP services have no fixed `ports:`; `dev-mode-wp.sh` publishes 5173 (Vite HMR) via a temporary `-f` override file and recreates the container without it on exit.

**Live-reload volume pattern.** Frontend project compose blocks bind-mount the whole app dir (`./apps/<name>:/app`) but use anonymous volumes to shadow `/app/node_modules` and `/app/.next` so the host's (possibly absent/stale) `node_modules` doesn't clobber the container's. This is why a plain restart doesn't pick up new dependencies — `scripts/restart-project.sh` exists specifically to `docker-compose build --no-cache` and `up --force-recreate --renew-anon-volumes`, discarding that anonymous volume so `npm install` reruns.

**Routing**: every project service gets Traefik labels (`traefik.http.routers.<name>.rule=Host(\`<name>.localhost\`)`); `scripts/sync-hosts.sh` greps all such labels out of `docker-compose.yml` and writes a single marked block into `/etc/hosts` (requires sudo, re-execs itself with `sudo` if needed).

## Conventions when adding/editing scripts

- `set -e` at the top of every script; colored output via the same `RED/GREEN/YELLOW/BLUE/NC` ANSI variable block copy-pasted per script.
- Every destructive or generative step is guarded and idempotent (see above) — don't add a step that fails on re-run against an already-scaffolded project.
- Container names are always `dockerator_<safe-name>`; compose service keys are always `<safe-name>` (hyphenated).
- A new Node framework needs: its lines in `scripts/lib/frameworks.sh` (stack, port, cache_volumes, dev_args, display) and, if it can be scaffolded, a `scripts/new-<type>.sh` + `scripts/templates/<type>/` directory + a case branch in `dockerator`'s `new)` handler. No new compose script or Dockerfile.
