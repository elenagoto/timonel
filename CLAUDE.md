# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Timonel is a bash CLI tool (not an app you build/test) that orchestrates Docker Compose to manage multiple local dev projects (Next.js, Vite+React, Parcel on a shared Node stack; WordPress and Laravel on a shared PHP stack) behind Traefik, with shared MySQL/Adminer/Mailpit services and automatic `*.localhost` domain routing. The repo itself is the tool; `apps/` (git-ignored) holds the projects it scaffolds and manages.

**Ongoing redesign:** the tool is being restructured (node/php stacks, `new` vs `add`, a single `dev`) and renamed to **timonel**. The plan and progress are in [ROADMAP.md](ROADMAP.md). Read it before starting work, and tick items off there.

## Commands

There is no build/lint/test suite — this is a shell script toolkit. To work on it:

```bash
./install.sh                       # symlinks `timonel` to /usr/local/bin, sets up shell completion, copies docker-compose.yml.example -> docker-compose.yml
timonel up / down                # start/stop shared services (Traefik, MySQL, Adminer, Mailpit)
timonel new nextjs|wp|vite|parcel <name> [--with-db]   # scaffold a fresh project (refuses an existing apps/<name>)
timonel new laravel <name> [--kit react|vue|svelte|livewire]  # Laravel (scripts/new-laravel.sh)
timonel add <name> [--with-db]   # dockerize an existing apps/<name> (scripts/add-project.sh)
timonel start|stop|restart <name>
timonel dev <name>               # dev shell in the project (scripts/dev-project.sh picks node or php dev mode)
timonel list                     # scripts/list-projects.sh
timonel logs [name]              # docker compose logs -f
timonel hosts                    # syncs *.localhost entries into /etc/hosts (needs sudo)
timonel open <name>              # opens apps/<name> in VS Code
timonel remove <name>            # asks (and whether to drop its DB, default keep), then removes container + anon volumes + image, compose block, apps/<name>
```

Manually testing a change to a `scripts/*.sh` file means running the corresponding `timonel <command>` against a scratch project in `apps/`.

## Architecture

**`timonel`** is a thin dispatcher: it resolves its own real path (so it works via symlink from `/usr/local/bin`), `cd`s there, and routes `timonel <command> ...` to a script in `scripts/`. Add new subcommands by adding a `case` branch here plus a new `scripts/<verb>-<noun>.sh`.

**`docker-compose.yml` is generated, not hand-edited.** `docker-compose.yml.example` is the checked-in template (defines `traefik`, `mysql`, `adminer`, `mailpit`, and `name: timonel`, so volumes and images are named `timonel_…` / `timonel-…` whatever the repo folder is called); `docker-compose.yml` itself is git-ignored and is mutated in place by `add-to-compose.sh` and `remove-from-compose.sh`, which splice per-project service blocks in with `insert_service_block` from `scripts/lib/compose.sh` (before the first top-level `volumes:`/`networks:` key). Read project services with `list_project_services` / `project_service_exists` / `service_label` from the same file, not `grep "^  name:"` (that also matches network and volume keys). Never hand-edit `docker-compose.yml` — edit `.example` for template changes, or fix the generating script for structural changes.

**Two-phase project creation.** Each `new-<type>.sh` script (e.g. `new-nextjs.sh`) does host-side scaffolding — creates `apps/<name>`, copies framework files from `scripts/templates/<type>/` (with `$APP_NAME`/`$SAFE_NAME` placeholders substituted via `sed`) — then registers the Traefik-routed service. Projects get their Docker files from their **stack**, not their framework: Node projects (Next.js, Vite, Parcel) the `Dockerfile` + `.dockerignore` from `scripts/templates/stacks/node/`; PHP projects (WordPress, Laravel) the `Dockerfile` + `.dockerignore` + `Caddyfile` from `scripts/templates/stacks/php/` (FrankenPHP 1.x / PHP 8.4, extensions for both frameworks, Composer, Node 24). All are registered by `add-to-compose.sh <name> <framework> [--with-db]`; PHP projects always get a database and a `WEB_ROOT` env var (`/app` for WordPress, `/app/public` for Laravel) that the Caddyfile reads.

**Framework settings live in one table.** `scripts/lib/frameworks.sh` (`framework_setting <framework> <key>`, a `case` function because macOS bash 3.2 has no associative arrays) holds each framework's stack, port, cache volumes, extra dev-server args and display name. `add-to-compose.sh` builds the compose block from it and labels it `timonel.stack=<stack>` / `timonel.framework=<framework>`. To know a registered project's framework, use `project_framework <name>` (the label, else `detect_framework` on its folder; Laravel and WordPress are checked before `package.json`, since they often have one for Vite) — `list`, `dev` and `restart` do; `add` calls `detect_framework` directly. Every step is idempotent/guarded (checks `[ -f ... ]` / `grep -q` before acting), so scripts are safe to re-run against a project that already partially exists — preserve that pattern in any new script.

**Name sanitization convention**, repeated across scripts: `SAFE_NAME`/`SAFE_URL` = lowercase, `_`→`-` (used for hostnames, container names, compose service keys); `SAFE_DB` = lowercase, `-`→`_` (used for MySQL db/user names). Both directions of translation appear depending on the script — check which one a given script uses before assuming. The `apps/` folder keeps the name *as typed* (e.g. `my_app`), so it can differ from the service key (`my-app`): never build `apps/$SAFE_NAME` — use `resolve_app_dir_name` from `scripts/lib/project.sh` (sourced, not executed), which reads the folder from the service's `build.context`. The dispatcher validates every project-name argument (`is_valid_project_name`: `[A-Za-z0-9][A-Za-z0-9_-]*`), rejects core-service names for `new`/`add`/`remove`, and rejects unexpected extra arguments on every command (`MAX_ARGS`; `new` and `add` parse their own `--with-db` / `--kit`).

**`new` vs `add`.** `new` only creates fresh projects: the dispatcher refuses it when `apps/<name>` exists or the service name is taken, and points to `add`. `add` (`scripts/add-project.sh`) dockerizes an existing folder: `detect_framework` guesses, then it **always asks** the user to confirm (numbered list, Enter = detected; a number or framework name is accepted; no tty + detection = detected), copies the stack's Docker files only if missing, creates the DB (php always, node with `--with-db`) and calls `add-to-compose.sh`. It never edits app files (for WordPress it only adds the Mailpit mu-plugin if missing and *prints* the DB settings when `wp-config.php` doesn't use `mysql`). On an already-registered project it skips the question and only fills in what's missing. New Next.js apps scaffolded from scratch always get TypeScript (`tsconfig.json`, `.tsx` files) and ESLint (`eslint.config.mjs`, same setup as `create-next-app`) from `scripts/templates/nextjs/`.

**Scaffolding runs in containers, never on the host.** `new-vite-react.sh` runs `npm create vite` in a throwaway `node:24-alpine` container with `--user "$(id -u):$(id -g)" -e HOME=/tmp`, so files stay owned by the user and no host Node/npm is needed. `new-laravel.sh` does the same with `composer:2` (`create-project --no-scripts`; starter kits `laravel/<kit>-starter-kit` with `--stability=dev`, exactly like Laravel's installer). Caveat for future scaffolders: some (e.g. `create-next-app`) call `os.userInfo()` and crash under a uid with no account in the container — run those as root and `chown` afterwards instead.

**Laravel setup.** `scripts/lib/laravel.sh` writes `.env` from `.env.example` (`set_env_value` replaces or uncomments `KEY=`; MySQL instead of SQLite, Mailpit, `APP_URL`, and `QUEUE_CONNECTION=sync` because no queue worker runs — with the `database` default, queued jobs would never run) and patches `vite.config.{ts,js}` for Docker (`host 0.0.0.0`, `port 5173`, `strictPort`, `hmr.host localhost`, inserted inside an existing `server: {` block; idempotent via the presence of `hmr`). `scripts/setup-laravel.sh <name> [--migrate] [--reinstall]` then runs in a one-off container of the project's own image (`docker compose run --rm --no-deps --user uid:gid`): composer install if `vendor/` is missing, `key:generate` if `APP_KEY` is empty, optional migrations, `npm install` + `npm run build` if missing (the welcome page needs `public/build`). `new laravel` runs it with `--migrate`; `add` runs it too (migrating only when it just created `.env`, and only *printing* the Vite setting, since `vite.config` is app code); `restart` on a Laravel project skips the image rebuild (the PHP image holds no project dependencies) and runs it with `--reinstall`.

**Database wiring is opt-in for Node projects, automatic for PHP (WordPress, Laravel).** Next.js, Vite and Parcel projects only get `DB_*` env vars + `depends_on: mysql (service_healthy)` in their compose block when `--with-db` is passed to `new` or `add` (threaded through to `add-to-compose.sh`). PHP projects always get both. All of them go through `scripts/create-db.sh <safe_db>`, which starts MySQL if needed (`up -d --wait mysql`) and idempotently creates the database + user (name = user = password). WordPress bakes the credentials into `wp-config.php` from `scripts/templates/wordpress/wp-config.php.template`, and gets a `wp-content/mu-plugins/timonel-mailpit.php` that routes `wp_mail` to Mailpit.

**PHP dev mode doesn't edit `docker-compose.yml`.** PHP services have no fixed `ports:`; `dev-mode-php.sh` (reached via `dev`) publishes 5173 (Vite HMR) via a temporary `-f` override file and recreates the container without it on exit. It opens WordPress in its theme folder and Laravel in `/app`, using the `timonel.framework` label (or `wp-config.php` / `artisan` for unlabelled projects).

**Live-reload volume pattern.** Every project block bind-mounts the whole app dir (`./apps/<name>:/app`). Node projects also get anonymous volumes for the framework's `cache_volumes` (always `/app/node_modules`, plus `/app/.next` for Next.js) so the host's (possibly absent/stale) `node_modules` doesn't clobber the container's. PHP projects shadow nothing: `vendor/` and theme `node_modules` stay in the project folder so the editor can see them. This is why a plain restart doesn't pick up new Node dependencies — `scripts/restart-project.sh` exists to `docker compose build --no-cache` and `up --force-recreate --renew-anon-volumes` for Node projects, discarding that anonymous volume so `npm install` reruns. For PHP projects it only recreates the container (the image holds no project dependencies) and, for Laravel, runs `setup-laravel.sh --reinstall`.

**`remove` and the shared commands.** `remove-project.sh` reads everything that depends on the compose block first (folder, `DB_NAME` env via `service_label`, image via `docker compose config --images`), asks all its questions up front (remove? drop the database too? — default keep), then runs `rm -fsv` (anonymous volumes included), removes the image, optionally `drop-db.sh`, the block and the folder. `down` and `logs` pass `--profile projects`: Compose's docs say plain `down` skips services in a profile; Compose 5.7 includes them anyway, but the flag keeps every version consistent. `up` deliberately doesn't (projects start one by one).

**Routing**: every project service gets Traefik labels (`traefik.http.routers.<name>.rule=Host(\`<name>.localhost\`)`); `scripts/sync-hosts.sh` greps all such labels out of `docker-compose.yml` and writes a single marked block into `/etc/hosts` (requires sudo, re-execs itself with `sudo` if needed).

## Conventions when adding/editing scripts

- `set -e` at the top of every script; colored output via the same `RED/GREEN/YELLOW/BLUE/NC` ANSI variable block copy-pasted per script.
- Every destructive or generative step is guarded and idempotent (see above) — don't add a step that fails on re-run against an already-scaffolded project.
- Container names are always `timonel_<safe-name>`; compose service keys are always `<safe-name>` (hyphenated).
- A new framework needs: its lines in `scripts/lib/frameworks.sh` (stack, port, cache_volumes, display, plus dev_args for node or web_root for php) and, if it can be scaffolded, a `scripts/new-<type>.sh` + `scripts/templates/<type>/` directory + a case branch in `timonel`'s `new)` handler. No new compose script or Dockerfile: the stack's shared files in `scripts/templates/stacks/<stack>/` are reused.
- When generating YAML or other text from bash, use `echo` lines (as `add-to-compose.sh` does) or a quoted heredoc (`<< 'EOF'`). In an unquoted heredoc, anything in backticks or `$(...)` is executed — a comment once ran `dockerator dev-wp` and pasted its output into `docker-compose.yml`.
- Scripts run under macOS's bash 3.2: no associative arrays, `mapfile`, `${var,,}` etc. Test `sed -i` usage on both BSD and GNU sed, or write to a temp file instead.
- Use `docker compose` (the Compose plugin), not the old standalone `docker-compose` command.
- Testing from Claude Code: its shell is **zsh**, which does not word-split unquoted variables (`set -- $p`, `cmd $LIST`, `$P up` with `P="docker compose -p x"`). Run such test snippets under `bash -c` / `bash <<'EOF'`, or the test itself is wrong (this produced several false "refused"/"failed" results during the redesign).
