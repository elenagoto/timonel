# Roadmap: Dockerator → Timonel

Tracks the redesign and rename of this tool. Tick items off as they land.

**Decisions so far**

- New name: **timonel** (helmsman: the one who steers).
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

---

## Target design

### Commands

```bash
timonel up | down                         # shared services (Traefik, MySQL, Adminer, Mailpit)
timonel new <template> <name> [--with-db] # scaffold: next, vite-react, parcel-react, wordpress, laravel
timonel add <name> [--with-db]            # dockerize an existing apps/<name>, framework auto-detected
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

## Phase 1: Restructure into stacks and templates

- [ ] One Node Dockerfile and one compose generator for the node stack (replaces the 3 near-identical `add-to-compose-*` scripts and Dockerfiles)
- [ ] Per-framework settings table (port, extra cache volume such as `/app/.next`)
- [ ] Write stack/framework labels into every service block
- [ ] `--with-db` works for every template, not just Next.js
- [ ] php stack: one shared PHP image and compose generator for WordPress and Laravel
  - [ ] Union of PHP extensions: mysqli, pdo_mysql, gd, imagick, exif, intl, zip, opcache, bcmath, pcntl
  - [ ] Composer in the image
  - [ ] Caddyfile web root from the framework settings (`/app` or `/app/public`)
  - [ ] Dev port 5173 mechanism from `dev-mode-wp.sh` generalised to the whole php stack
- [ ] Scaffolding runs in a temporary container (Vite: drop the "npm required on your Mac" prerequisite)
- [x] Shared helper that lists project services from the `services:` section only. Use it in `list`, both completions and the name checks. *(Audit: `grep "^  name:"` also matches the `dockerator:` network key, and filtering on "mysql" hides projects with "mysql" in their name.)*
- [x] Make the compose insert keep the last line of the file *(found while testing: the `while read` loop drops a final line without a trailing newline, e.g. `driver: bridge`)*
- [ ] **Updates** *(audit)*, done once in the shared templates:
  - [ ] Node 20 (end-of-life April 2026) → `node:24-alpine` everywhere (also in the PHP image, replacing `setup_20.x`)
  - [ ] FrankenPHP `php8.3` → `php8.4` (current Laravel supports it)
  - [ ] Pin `adminer` and `mailpit` image versions instead of `latest`
- [ ] **Templates** *(audit)*:
  - [ ] Next: add ESLint with Next's recommended config and a `lint` script (Next 16 removed `next lint`; dev mode already advertises `npm run lint`)
  - [ ] Parcel: update `parcel` 2.12; drop or replace `eslint@8` + `eslint-config-react-app` (end-of-life/unmaintained) and `react-feather` (→ `lucide-react`); move lint tools to devDependencies; `styles.css` is loaded twice

## Phase 2: `add` and unified `dev`

- [ ] `add <name>`: detect the framework, copy Dockerfile and `.dockerignore` only if missing, never touch app files
- [ ] Move the "existing Next.js project" behaviour from `new nextjs` into `add`; `new` always scaffolds
- [ ] `dev <name>`: one command; the php stack publishes 5173 during the session; tailored hints per framework
- [ ] Remove `dev-wp`, `dev-front`, `dev-nextjs`, `dev-vite`
- [ ] Flags are validated: an unknown or misplaced flag is an error, not silently ignored *(audit: `--with-db` was ignored for non-Next types)*
- [ ] `remove` cleanup *(audit)*: delete anonymous volumes (`rm -v`), the built image, and optionally the project's database and user; run `hosts` instead of telling you to edit `/etc/hosts` with nano
- [ ] Verify `down` and `logs` (no name) include project containers, which sit in the `projects` profile. Add `--profile projects` if not.
- [ ] **Laravel**:
  - [ ] `new laravel <name>`: `composer create-project laravel/laravel` in a temporary container
  - [ ] Write `.env` (MySQL instead of the SQLite default, Mailpit, `APP_URL=http://<name>.localhost`), then `key:generate` and `migrate`
  - [ ] Database via `create-db.sh` (always, like WordPress)
  - [ ] `add` detects Laravel and fills in a missing `.env` from `.env.example` with the same settings
  - [ ] `dev`: shell at `/app` with `php artisan` available; Vite via `laravel-vite-plugin` on 5173 (needs `server.host` + `hmr.host` set for Docker)
  - [ ] `restart` runs `composer install` + `npm install`
  - [ ] Check that `storage/` and `bootstrap/cache` are writable through the bind mount (fine on macOS; can need a fix on Linux)
  - [ ] Out of scope for now: queue worker, scheduler, Octane

## Phase 3: Rename to timonel and fresh setup

- [ ] Rename the dispatcher, completion files and functions, `~/.dockerator-path`, container prefix `timonel_`, network, `timonel-adminer.localhost` / `timonel-mailpit.localhost`, `/etc/hosts` markers, MySQL root password, reserved names, Traefik router names
- [ ] Set an explicit compose project name (`name: timonel`) so volume names no longer depend on the folder name
- [ ] Switch `docker-compose` → `docker compose` everywhere *(audit)*
- [ ] Expose MySQL 3306, Traefik dashboard 8080 and Mailpit 1025 on `127.0.0.1` only *(audit: currently open to the LAN)*
- [ ] Dispatcher cleanup *(audit)*: remove the `DEBUG:` echoes in `hosts`; move the `chmod` self-fix after symlink resolution (or drop it); regenerate the help text from the real command list
- [ ] `install.sh` *(audit)*: quote `$(pwd)`; work from any directory; add the zsh completion folder to `fpath`; remove the old `dockerator` symlink and completion if present
- [ ] **Fresh start** (confirm the exact list before deleting): old project containers and images, `apps/*`, `dockerator_mysql_data` volume, `dockerator` network, old `/etc/hosts` block. *Leave `devner_mysql_data` alone: it belongs to another tool.*
- [ ] Rename the local folder and the GitHub repo (you), then update the clone URL in the README
- [ ] `hosts` becomes optional: drop the "run `hosts`" reminders and `/etc/hosts` checks from `new`/`add`/`remove`; README explains when it's needed

## Phase 4: Command log

- [ ] Each run appends timestamp, command and exit code to `logs/timonel.log` (already git-ignored)
- [ ] Full output (colours stripped) for non-interactive commands; start/exit lines only for `dev` and `logs`
- [ ] Size cap (e.g. last ~5,000 lines)
- [ ] `timonel history` and `timonel history --errors`

## Docs (alongside each phase)

- [ ] Rewrite README around stacks, `new` vs `add`, and `dev` *(audit: features list misses Vite/Parcel; points to a missing `example` environment block)*
- [ ] Add an MIT `LICENSE` file (the README already links to it)
- [ ] Update CLAUDE.md after each phase

## Dropped

- Commit `7d78e53`'s message overstates its change (a comment only). History; nothing to fix.
- Separate fixes to `dev-front` text, `list` type detection and stale `new` usage text: replaced by the unified `dev`, labels and the new dispatcher.
