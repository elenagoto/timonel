# Roadmap: Dockerator → Timonel

Tracks the redesign and rename of this tool. Tick items off as they land.

**Decisions so far**

- New name: **timonel** (helmsman: the one who steers). Also considered: muelle, estiba, zarpa, batuta, and maestro (dropped: the `maestro` command is already used by mobile.dev's popular mobile-testing tool).
- Fresh start: existing projects in `apps/`, their containers and the old MySQL volume are not migrated.
- Two **stacks** instead of four project types: **node** (Next, Vite, Parcel…) and **php** (WordPress and Laravel).
- Laravel is built together with the php stack (phases 1–2), so the stack is shaped by two real frameworks rather than WordPress quirks alone.
- Separate **`new`** (scaffold from a template) from **`add`** (wire up a project that already exists in `apps/`).
- A single **`dev`** command for every project.
- One thing at a time, in the phase order below.
- Keep the `parcel-react` template (with updated dependencies).
- Keep `hosts`, but make it optional: no more "run `hosts`" reminders after `new`/`add`; the README explains when it's needed (Safari, CLI tools).
- `remove` always deletes the project folder after confirmation, also for projects brought in with `add`.
- License: MIT.
- New Next.js projects get ESLint with Next's recommended config and a `lint` script.
- Phase 2 decisions:
  - Template names stay short: `nextjs`, `vite`, `parcel`, `wp`, plus `laravel`.
  - `new` only creates fresh projects: if `apps/<name>` already exists it stops and suggests `add`.
  - `add` auto-detects the framework, then **always asks you to confirm** it (or pick another).
  - `remove` asks whether to also delete the project's database and user; the default (Enter) keeps them.
  - The old `dev-wp`, `dev-front`, `dev-nextjs`, `dev-vite` commands are removed; only `dev` remains.
  - `new laravel` creates the plain skeleton; `--kit react|vue|livewire` adds a Laravel starter kit.

---

## Target design

### Commands

```bash
timonel up | down                         # shared services (Traefik, MySQL, Adminer, Mailpit)
timonel new <template> <name> [--with-db] # scaffold: nextjs, vite, parcel, wp, laravel [--kit react|vue|livewire]
timonel add <name> [--with-db]            # dockerize an existing apps/<name>; framework detected, then confirmed
timonel dev <name>                        # shell into the project (php: also publishes Vite port 5173)
timonel start | stop | restart <name>
timonel list | open <name> | logs [name] | remove <name> | hosts
timonel history [--errors]                # command log (phase 4)
```

### Model

| Stack | Templates | Container | Dev port |
|---|---|---|---|
| node | `next`, `vite-react`, `parcel-react` | One shared Node Dockerfile, `npm run dev` | From the framework: next 3000, vite 5173, parcel 1234 |
| php | `wordpress`, `laravel` | FrankenPHP + Composer + Node (for Vite assets) | 80, plus 5173 only while `dev` is open |

- **Templates are folders** (`templates/<template>/`) plus a small table of per-framework settings (port, cache folders to shadow, PHP web root). Adding a framework should not need new scripts.
- **php stack, WordPress vs Laravel:**

  | Aspect | WordPress | Laravel |
  | --- | --- | --- |
  | Web root | `/app` | `/app/public` |
  | Dependencies | none | Composer; `vendor/` stays in the project folder (VS Code autocomplete), unlike `node_modules` |
  | Config | `wp-config.php` from a template | `.env`: `DB_CONNECTION=mysql` (Laravel defaults to SQLite), `DB_HOST=mysql`, DB name/user/password, `MAIL_HOST=mailpit`, `MAIL_PORT=1025`, `APP_URL` |
  | Database | always | always |
  | Mail → Mailpit | mu-plugin | `.env` |
  | `restart` reinstalls | — | `composer install` + `npm install` |

- **Scaffold inside a temporary container**, never on the Mac: `composer create-project` for Laravel, `npm create vite` for Vite. No local PHP or npm needed.
- **Store each project's stack and framework as compose labels** (e.g. `timonel.stack=node`, `timonel.framework=next`). `dev`, `list`, `restart` and `remove` read them instead of guessing from files. This also fixes "list shows Parcel as Next.js".
- **`add` detection, in this order:** `artisan` + `laravel/framework` in `composer.json` (Laravel; checked before `package.json` because Laravel projects have one too), then `wp-config.php` or `wp-content/` (WordPress), then the `package.json` dependency `next`/`vite`/`parcel`. Unknown means fail with a clear message.

---

## Phase 0: Bug fixes from the audit (done: commits 71b7b19, 5523832)

- [x] Restore `scripts/new-parcel.sh` (overwritten by the README in 78b2803)
- [x] `remove-from-compose.sh` removes only the target block (it could delete other projects)
- [x] Re-running `new wp` no longer wipes the theme
- [x] WP port 5173 only published during dev mode (temporary override file, compose file untouched)
- [x] `create-db.sh`: databases are actually created (WordPress and Next.js `--with-db`), starting MySQL if needed
- [x] WordPress mail goes to Mailpit (mu-plugin)
- [x] Next.js `src/components` and `public/` created at the right paths
- [x] Vite config patch is idempotent and works on Linux
- [x] Name validation and reserved names; folder lookup for `my_app` vs `my-app`
- [x] Dev-mode instructions no longer tell you to kill the dev server
- [x] Removed hardcoded `platform: linux/arm64`
- [x] README and CLAUDE.md updated
- [x] Commit these

## Phase 1: Restructure into stacks and templates (done: commits 96ed703, 3e322e0, 20a8aaa, 8a580df, 6a62cbd, 870ad08 + docs)

- [x] One Node Dockerfile and one compose generator for the node stack (`templates/stacks/node/`, `add-to-compose.sh`; replaces the 3 near-identical `add-to-compose-*` scripts and Dockerfiles)
- [x] Per-framework settings table (`scripts/lib/frameworks.sh`: stack, port, cache volumes, dev args, web root, display name)
  - [x] php entries: wordpress and laravel (port 80, web root `/app` / `/app/public`)
- [x] Write stack/framework labels into every service block (Node and PHP); `list` and PHP dev mode read them
- [x] `--with-db` works for Next.js, Vite and Parcel; the dispatcher rejects unknown flags after the name (WordPress always gets a database)
- [x] All three Node frameworks built and served from the shared image (Vite also answers for a `*.localhost` Host header, as Traefik sends it)
- [x] php stack: one shared PHP image (`templates/stacks/php/`) and the same `add-to-compose.sh` for WordPress and Laravel (`add-to-compose-wp.sh` removed)
  - [x] Union of PHP extensions: mysqli, pdo_mysql, gd, imagick, exif, intl, zip, opcache, bcmath, pcntl
  - [x] Composer in the image (plus git/unzip for it)
  - [x] Caddyfile web root from the framework settings via `WEB_ROOT` (`/app` or `/app/public`)
  - [x] Dev port 5173 mechanism generalised to the whole php stack (`dev-mode-php.sh`, still the `dev-wp` command until phase 2)
  - Verified: a scaffolded WordPress reaches its install page against MySQL; a Laravel 13 app created with `composer create-project` inside the image is served from `public/`
- [x] Scaffolding runs in a temporary container: Vite uses `node:24-alpine` with your user id, so files stay yours; npm is no longer a prerequisite. (Laravel's `composer create-project` follows the same pattern in phase 2.)
- [x] Shared helper that lists project services from the `services:` section only. Used by `list` and both completions. *(Audit: `grep "^  name:"` also matches the `dockerator:` network key, and filtering on "mysql" hides projects with "mysql" in their name.)*
- [x] Use it for the per-script "is this project in the compose file?" checks too (`project_service_exists`): done in `add-to-compose.sh`, all four `new-*` scripts and `dev-mode-php.sh`. The rest moved to phase 2.
- [x] Make the compose insert keep the last line of the file *(found while testing: the `while read` loop drops a final line without a trailing newline, e.g. `driver: bridge`)*
- [x] **Updates** *(audit)*:
  - [x] Node 20 (end-of-life April 2026) → `node:24-alpine` everywhere (also in the PHP image, replacing `setup_20.x`)
  - [x] FrankenPHP `latest-php8.3` → `1-php8.4` (major version pinned; current Laravel supports PHP 8.4)
  - [x] Pin `adminer:6` and `axllent/mailpit:v1.32` instead of `latest`
- [x] **Templates** *(audit)*:
  - [x] Next: ESLint 9 with `eslint-config-next` (Core Web Vitals + TypeScript) and a `lint` script, matching `create-next-app`; Next ^16.4.6; `@types/node` ^24; tsconfig aligned with Next 16 (`jsx: react-jsx`). TypeScript stays on 5, as `create-next-app` still uses it
  - [x] Parcel: `parcel` ^2.16.4; dropped `eslint@8` + `eslint-config-react-app` (no lint script used them); `react-feather` → `lucide-react`; build tools moved to devDependencies; `styles.css` only imported from `src/index.js`
  - Verified: Next lint/type-check/dev pass; Parcel dev and production build pass
- Note for phase 2: `create-next-app` (and possibly other scaffolders) fails when run in a container as your user id (`os.userInfo()` finds no account). Vite's doesn't. Container scaffolding for those needs another way to keep file ownership (e.g. run as root, then `chown`).

## Phase 2: `add`, unified `dev`, Laravel (done: commits 97faaed, 9567d03, 81dbb68, 11a357a, 67703ca + docs)

- [x] `add <name> [--with-db]` (`add-project.sh`): detect the framework, **ask to confirm or pick another**, copy the stack's Docker files only if missing, never touch app files (WordPress: adds the Mailpit mu-plugin if missing, *prints* DB settings if `wp-config.php` doesn't use `mysql`); safe to re-run on a registered project; `add <Tab>` suggests unregistered folders
- [x] Move the "existing Next.js project" behaviour from `new nextjs` into `add`; `new` stops with "use `add`" if `apps/<name>` exists (or the service name is taken)
- [x] Laravel part of `add` (fill a missing `.env`): done in the Laravel group below
- [x] `dev <name>`: one command (`dev-project.sh` → `dev-mode-node.sh` / `dev-mode-php.sh`); the php stack publishes 5173 during the session; tailored hints per framework
- [x] Remove `dev-wp`, `dev-front`, `dev-nextjs`, `dev-vite` (dispatcher, completions, `list` footer, docs)
- [x] Shared framework detection (`detect_framework`, `project_framework` in `frameworks.sh`): label first, else files; Laravel/WordPress checked before `package.json`. Used by `dev` and `list`; `add` will reuse it
- [x] Flags are validated: an unknown or misplaced flag is an error, not silently ignored *(audit: `--with-db` was ignored for non-Next types)*. `new` and `add` check `--with-db`; every other command rejects extra arguments.
- [x] Replace the remaining `grep "^  name:"` checks with `project_service_exists` (start, stop, restart, remove, remove-from-compose). None left.
- [x] `remove` cleanup *(audit)*: asks first, then deletes the container with its anonymous volumes (`rm -fsv`) and the built image; **asks** whether to delete the project's database and user (`drop-db.sh`, default: keep); points to `dockerator hosts` instead of `/etc/hosts` with nano
- [x] Verify `down` and `logs` include project containers (`projects` profile). Docs say plain `down` skips profiled services, but Compose 5.7 includes them; `--profile projects` added to both so every version behaves the same. `logs <name>` also accepts the folder form (`my_app`).
- [x] **Laravel**:
  - [x] `new laravel <name>`: `composer create-project laravel/laravel` in a temporary `composer:2` container, as the user (`new-laravel.sh`)
  - [x] `--kit react|vue|svelte|livewire` (Svelte was added to Laravel's kits since the decision): `laravel/<kit>-starter-kit` with `--stability=dev`, which is what `laravel new` installs (current `dev-main`, Laravel 13; the tagged releases are old)
  - [x] Write `.env` (MySQL instead of the SQLite default, Mailpit, `APP_URL=http://<name>.localhost`), then `key:generate` and `migrate` (`lib/laravel.sh`, `setup-laravel.sh` in a one-off container of the project image)
  - [x] Database via `create-db.sh` (always, like WordPress)
  - [x] `add` detects Laravel and fills in a missing `.env` from `.env.example` with the same settings; installs what's missing; prints (doesn't apply) the Vite setting
  - [x] `dev`: shell at `/app` with `php artisan` available; Vite patched for Docker (`host 0.0.0.0`, `hmr.host localhost`, per Laravel's Sail docs) and reached on 5173
  - [x] `restart` re-runs `composer install` + `npm install` + build (and no longer rebuilds the PHP image, which holds no project deps)
  - [x] `storage/` writable through the bind mount (checked on macOS). On Linux, files are created as your user (`--user`), so it should hold there too, but it's untested on Linux.
  - Verified end to end (isolated scratch stack): plain project and React kit served (HTTP 200, login page for the kit), migrations in MySQL, files owned by the user; Vite dev server reachable from the Mac with CORS for `*.localhost`; `add` on a downloaded repo (no `.env`/`vendor`/`node_modules`) → served in 17 s; `restart`; re-running `add`
  - [x] `.env` gets `QUEUE_CONNECTION=sync`, so queued jobs (e.g. mail to Mailpit) run without a worker
  - Out of scope for now (README "Ideas for Contributions"): queue worker and scheduler (likely an optional extra container per project, same image, `queue:work` / `schedule:work`); Octane (production-oriented, least useful locally)

## Phase 3: Rename to timonel and fresh setup

- [ ] Rename the dispatcher, completion files and functions, `~/.dockerator-path`, container prefix `timonel_`, network, `timonel-adminer.localhost` / `timonel-mailpit.localhost`, `/etc/hosts` markers, MySQL root password, reserved names, Traefik router names
- [ ] Set an explicit compose project name (`name: timonel`) so volume names no longer depend on the folder name
- [ ] Switch `docker-compose` → `docker compose` everywhere *(audit)*
- [ ] Expose MySQL 3306, Traefik dashboard 8080 and Mailpit 1025 on `127.0.0.1` only *(audit: currently open to the LAN)*
- [ ] Dispatcher cleanup *(audit)*: remove the `DEBUG:` echoes in `hosts`; move the `chmod` self-fix after symlink resolution (or drop it); regenerate the help text from the real command list
- [ ] `install.sh` *(audit)*: quote `$(pwd)`; work from any directory; add the zsh completion folder to `fpath`; remove the old `dockerator` symlink and completion if present
- [ ] **Fresh start** (confirm the exact list before deleting): old project containers and images, `apps/*`, `dockerator_mysql_data` volume, `dockerator` network, old `/etc/hosts` block. *Leave `devner_mysql_data` alone: it belongs to another tool.*
- [ ] Rename the local folder and the GitHub repo (you), then update the clone URL in the README
  - **Rename** `elenagoto/dockerator` → `timonel` in GitHub's repo settings. GitHub then redirects the old URL (web pages and `git clone/pull/push`) to the new one, so the link already sent on CVs keeps working.
  - **Never create a new repo named `dockerator`** on the account: GitHub drops the redirect when the old name is reused, and CV visitors would land on that repo instead.
  - Add "Formerly known as Dockerator" near the top of the README, so visitors from the old link know they're in the right place.
  - Update the CV link for future applications (old copies keep working via the redirect).
- [ ] `hosts` becomes optional: drop the "run `hosts`" reminders and `/etc/hosts` checks from `new`/`add`/`remove`; README explains when it's needed

## Phase 4: Command log

- [ ] Each run appends timestamp, command and exit code to `logs/timonel.log` (already git-ignored)
- [ ] Full output (colours stripped) for non-interactive commands; start/exit lines only for `dev` and `logs`
- [ ] Size cap (e.g. last ~5,000 lines)
- [ ] `timonel history` and `timonel history --errors`

## Docs (alongside each phase)

- [ ] Rewrite README around stacks, `new` vs `add`, and `dev`
  - [x] Phase 1: Stacks section; Vite and Parcel usage; features list includes Vite/Parcel *(audit)*; no longer points to a missing `example` environment block *(audit)*
  - [x] Phase 2: `new` vs `add` (Usage overview table), single `dev`, Laravel usage and dev mode, database info for PHP projects, `remove` behaviour, common mistake "`new` on a downloaded project"
- [ ] Add an MIT `LICENSE` file (the README already links to it)
- [ ] Update CLAUDE.md after each phase

## Dropped

- Commit `7d78e53`'s message overstates its change (a comment only). History; nothing to fix.
- Separate fixes to `dev-front` text, `list` type detection and stale `new` usage text: replaced by the unified `dev`, labels and the new dispatcher.
