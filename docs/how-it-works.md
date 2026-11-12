# How it works

[Documentation](README.md) › How it works

This page is for contributors: how Timonel is built, and how to change it. Timonel is a set of bash scripts around Docker Compose; there is nothing to compile.

## The big picture

```text
browser ──▶ http://my-app.localhost
              │
              ▼
           Traefik (port 80) ── reads each container's labels ──▶ routes to the right project
              │
              ├──▶ timonel_my-app      (Node stack: dev server on port 3000, 5173 or 1234)
              ├──▶ timonel_my-site     (PHP stack: FrankenPHP on port 80)
              │
              └── shared: timonel_mysql, timonel_adminer, timonel_mailpit
```

- **One Compose project**, named `timonel`, holds the four shared services and every registered project. Projects carry a Compose profile (`projects`), so `timonel up` starts only the shared services.
- **Traefik** routes `<name>.localhost` to a project's container, using the labels on that container.
- **Every project folder** (`apps/<name>`) is mounted into its container at `/app`, so edits on your machine show up instantly.

## Stacks and frameworks

Projects run on one of two shared setups, called **stacks**. A framework only decides a few settings.

| Stack | Frameworks | Image | Notes |
| --- | --- | --- | --- |
| **node** | Next.js, Vite, Parcel | `node:24-alpine` | The dev server is the container's main process. `node_modules` (and `.next`) live in anonymous volumes, so the host's copy never interferes. |
| **php** | WordPress, Laravel | FrankenPHP 1.x, PHP 8.4, Composer, Node 24 | Serves the site on port 80. `vendor/` and `node_modules/` stay in the project folder, visible to your editor. |

The per-framework settings live in one table, [`scripts/lib/frameworks.sh`](https://github.com/elenagoto/timonel/blob/main/scripts/lib/frameworks.sh) (a bash `case` function, because macOS ships bash 3.2):

| Setting | Meaning | Example |
| --- | --- | --- |
| `stack` | `node` or `php` | `next` → `node` |
| `port` | Port the app listens on inside the container | `vite` → `5173` |
| `cache_volumes` | Folders kept in anonymous volumes | `next` → `/app/node_modules /app/.next` |
| `dev_args` | Extra flags for `npm run dev` (node) | `vite` → `--host 0.0.0.0` |
| `web_root` | Document root (php) | `laravel` → `/app/public` |
| `display` | Name shown by `list` | `parcel` → `Parcel` |

Each stack's shared files (`Dockerfile`, `.dockerignore`, and a `Caddyfile` for PHP) live in [`scripts/templates/stacks/`](https://github.com/elenagoto/timonel/tree/main/scripts/templates/stacks) and are copied into each project.

## The compose file

`docker-compose.yml` is **generated** and git-ignored. It starts as a copy of [`docker-compose.yml.example`](https://github.com/elenagoto/timonel/blob/main/docker-compose.yml.example) (the shared services), and the scripts add and remove one block per project:

- [`scripts/add-to-compose.sh`](https://github.com/elenagoto/timonel/blob/main/scripts/add-to-compose.sh) builds a project's block from the framework settings: Traefik labels, volumes, database environment variables, and two labels of its own, `timonel.stack` and `timonel.framework`.
- [`scripts/lib/compose.sh`](https://github.com/elenagoto/timonel/blob/main/scripts/lib/compose.sh) inserts blocks, lists projects, checks whether one exists and reads labels.
- `remove-from-compose.sh` removes a block by its indentation.

Commands that need a project's framework read the `timonel.framework` label, and fall back to guessing from the project's files (`detect_framework`).

## Commands and scripts

The `timonel` file is only a dispatcher: it checks the arguments, then runs one script from `scripts/`.

| Command | Script |
| --- | --- |
| `new <type>` | `new-nextjs.sh`, `new-vite-react.sh`, `new-parcel.sh`, `new-wordpress.sh`, `new-laravel.sh` |
| `add` | `add-project.sh` |
| `dev` | `dev-project.sh` → `dev-mode-node.sh` or `dev-mode-php.sh` |
| `start`, `stop`, `restart` | `start-project.sh`, `stop-project.sh`, `restart-project.sh` |
| `list`, `open`, `remove`, `hosts` | `list-projects.sh`, `open-project.sh`, `remove-project.sh`, `sync-hosts.sh` |

Helpers used by several scripts:

| Script | Role |
| --- | --- |
| `create-db.sh`, `drop-db.sh` | Create or delete a project's database and user (starting MySQL if needed) |
| `setup-laravel.sh` | Install what a Laravel project is missing, in a one-off container of its own image |
| `lib/project.sh` | Name validation, reserved names, finding a project's folder |
| `lib/laravel.sh` | Writing Laravel's `.env` and preparing `vite.config` for Docker |

New projects are created **inside containers**, so the host needs nothing but Docker: Vite's scaffolder runs in `node:24-alpine`, Laravel's `composer create-project` in `composer:2`, both as your own user so the files belong to you.

## Repository layout

```text
timonel/
├── timonel                     # the command (dispatcher)
├── install.sh                  # installer
├── docker-compose.yml.example  # template: the shared services
├── timonel-completion.bash     # tab completion
├── timonel-completion.zsh
├── mkdocs.yml                  # documentation website config
├── docs/                       # this documentation
├── scripts/
│   ├── templates/
│   │   ├── stacks/node/        # shared Node Dockerfile + .dockerignore
│   │   ├── stacks/php/         # shared PHP Dockerfile + Caddyfile + .dockerignore
│   │   ├── nextjs/, parcel/    # starter files for `new`
│   │   └── wordpress/          # wp-config template, Mailpit must-use plugin
│   ├── lib/                    # shared helpers (compose, frameworks, project, laravel)
│   └── *.sh                    # one script per command or task
└── apps/                       # your projects (git-ignored)
```

## Adding a framework

1. **Settings:** add its lines to `scripts/lib/frameworks.sh` (`stack`, `port`, `cache_volumes`, `display`, plus `dev_args` for node or `web_root` for php) and its name to `KNOWN_FRAMEWORKS`. That's enough for `add` to register it and for `dev`, `list` and `restart` to handle it.
2. **Detection** (optional): teach `detect_framework` in the same file to recognise it, so `add` can suggest it.
3. **Scaffolding** (optional, for `new`): a `scripts/new-<type>.sh`, a `scripts/templates/<type>/` folder if it has starter files, and a branch in the `new)` section of the `timonel` dispatcher.

No new Dockerfile or compose script is needed: the stack's shared files are reused.

## Conventions

- `set -e` at the top of every script.
- Every step is **safe to re-run**: check before acting (`[ -f … ]`, `project_service_exists`), so scripts work on half-finished projects.
- Scripts run on **bash 3.2** (macOS): no associative arrays, `mapfile` or `${var,,}`. Write `sed -i` edits to a temporary file instead, since BSD and GNU `sed` differ.
- Use `docker compose` (the plugin), not the old `docker-compose` command.
- Generate YAML with `echo` lines or a quoted heredoc (`<< 'EOF'`): in an unquoted heredoc, backticks and `$(…)` are executed.
- Read project information with the helpers in `lib/compose.sh`, never with `grep "^  name:"`, which also matches network and volume keys.

## Testing a change

There is no automated test suite. Test against a scratch project:

```bash
timonel new nextjs scratch-test
timonel start scratch-test
# … try the change …
timonel remove scratch-test
```

For changes to the compose handling, work on a copy of the repository with a different project name in its `docker-compose.yml` (`name: timonel-test`), so your real projects aren't touched.

## Documentation

The `docs/` folder is published as a website with [Zensical](https://zensical.org/) (the successor of Material for MkDocs), configured in `mkdocs.yml`. GitHub builds and publishes it on every push to `main`. To preview it locally with Docker, from the repository folder:

```bash
docker run --rm -it -p 8000:8000 -v "$PWD":/docs zensical/zensical
```

Then open <http://localhost:8000/timonel/>; the preview updates as you edit. Pages must read well both on GitHub and on the site: use relative links between pages, plain blockquotes for notes, and no emoji in headings.

## Project plans

[`ROADMAP.md`](https://github.com/elenagoto/timonel/blob/main/ROADMAP.md) records the redesign from Dockerator to Timonel and what's still planned. Ideas welcome, especially: a Laravel queue worker and scheduler, backup and restore, PostgreSQL support, and Windows (WSL2) support. Fork the repository, create a branch, and open a pull request.
