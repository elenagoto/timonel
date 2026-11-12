# Timonel 🐳

> A Docker orchestration CLI tool for running many local projects side by side (Next.js, Vite, Parcel, WordPress, Laravel) with automatic routing and zero configuration. Create new projects, or drop in ones you downloaded.

Inspired by devner by [MarJC5](https://github.com/MarJC5).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ✨ Features

- 🚀 **One-command project creation** - `timonel new nextjs|vite|parcel|wp|laravel <name>`, Laravel with optional starter kits (`--kit react|vue|svelte|livewire`)
- 📥 **Bring your own project** - `timonel add <name>` dockerizes a downloaded project (course repo, client site) without touching its code
- 🧑‍💻 **One dev command** - `timonel dev <name>` opens a shell in any project, with hints for its framework
- 📘 **TypeScript by default** - New Next.js projects scaffold as TypeScript (strict mode) with ESLint, not JavaScript
- 🧱 **Two shared images** - one Node 24 image for every JavaScript project, one PHP 8.4 (FrankenPHP) image for WordPress and Laravel
- 🐳 **Only Docker needed** - no Node.js, npm, PHP or Composer on your machine; even the scaffolders run in containers
- 🗄️ **Shared services** - MySQL, Adminer, Mailpit across all projects
- 🔌 **Database wiring** - automatic for WordPress and Laravel; opt-in (`--with-db`) for Next.js, Vite and Parcel
- 🔄 **Hot reload** - Changes reflect immediately (Next.js, Vite, Parcel, and Vite in WordPress themes and Laravel)
- 🌐 **Clean URLs** - `project-name.localhost` for each project
- 🔐 **Auto /etc/hosts sync** - No manual editing
- 📋 **Project management** - List, open, and manage all projects
- ⚡ **Shell autocomplete** - Tab completion for commands and projects
- 🎨 **VS Code integration** - Open projects directly from CLI

---

## 📋 Prerequisites

- **Docker Desktop** installed and running ([Download](https://www.docker.com/products/docker-desktop))
- **macOS** or **Linux**
- Basic terminal knowledge

```bash
# Verify Docker is running
docker --version
```

---

## 🚀 Quick Start

```bash
# 1. Clone and install (links the `timonel` command, sets up tab completion)
git clone https://github.com/elenagoto/dockerator.git timonel
bash timonel/install.sh

# 2. In a new terminal window: start the shared services
timonel up
```

`install.sh` can be run from any folder and again at any time (it only does what's missing). It also cleans up an older `dockerator` install.

> **Do I need `timonel hosts`?** Usually not: Chrome, Firefox and Edge open any `*.localhost` address by themselves. Safari and some command-line tools may not; if a project opens in Chrome but not there, run `timonel hosts` once after adding projects (it writes the names into `/etc/hosts` and asks for your password).

---

## 🌐 Access Services

- 🎛️ **Traefik Dashboard**: http://localhost:8080 (this Mac only)
- 🐬 **MySQL** for local tools (TablePlus, Sequel Ace...): `127.0.0.1:3306`, user `root`, password `timonel` (this Mac only)
- 🗄️ **Adminer** (Database): http://timonel-adminer.localhost
  - Server: `mysql` | User: `root` | Pass: `timonel`
- 📧 **Mailpit** (Email Testing): http://timonel-mailpit.localhost
  - WordPress projects send all their mail here automatically (via a small `timonel-mailpit.php` must-use plugin), and so do Laravel projects (`MAIL_HOST=mailpit` in their `.env`)
  - Other apps: SMTP host `mailpit`, port `1025`, no auth/TLS (apps running outside Docker: `127.0.0.1:1025`)

The dashboard, MySQL and Mailpit's SMTP port only accept connections from your own Mac, not from other devices on your network. Project sites on port 80 are reachable as before.

---

## 🧱 Stacks

Every project runs on one of two shared setups. The framework only decides a few settings (port, web root, cache folders), all kept in `scripts/lib/frameworks.sh`.

| Stack | Frameworks | Image | Dev server port |
| --- | --- | --- | --- |
| **node** | Next.js, Vite, Parcel | `node:24-alpine` (`scripts/templates/stacks/node/`) | Next.js 3000, Vite 5173, Parcel 1234 |
| **php** | WordPress, Laravel | FrankenPHP 1.x, PHP 8.4, Composer, Node 24 (`scripts/templates/stacks/php/`) | 80 (+ 5173 for Vite while `dev` is open) |

Each project's block in `docker-compose.yml` is labelled with its stack and framework (`timonel.stack`, `timonel.framework`), which `list`, `dev` and `restart` read.

---

## 📖 Usage

Three commands cover a project's life:

| You want to… | Command | |
| --- | --- | --- |
| Start a **new** project from a template | `timonel new <type> <name>` | [Creating Projects](#creating-projects) |
| Run a project you **already have** in `apps/<name>` | `timonel add <name>` | [Bringing In Existing Projects](#-bringing-in-existing-projects) |
| Work inside a project (install packages, run tools) | `timonel dev <name>` | [Dev Mode](#-dev-mode) |

### Creating Projects

> **Project names** may contain letters, digits, `-` and `_`, and must start with a letter or digit (e.g. `my-app`, `my_app`, `MyApp`). The names `traefik`, `mysql`, `adminer`, `mailpit` and `timonel` are reserved.
>
> The folder keeps the name exactly as you typed it (`apps/my_app`), while the URL and container use a lowercase, hyphenated form (`my-app.localhost`). Every command accepts either form: `timonel open my_app` and `timonel open my-app` both work.

#### Next.js Project

```bash
timonel new nextjs my-app
timonel start my-app
# Visit: http://my-app.localhost
```

Scaffolds a **TypeScript** Next.js app (strict mode) — `src/app/page.tsx`, `src/app/layout.tsx`, a `tsconfig.json` and an `eslint.config.mjs` (Next's recommended rules, as `create-next-app` sets up) at the project root. Inside dev mode, `npm run lint` lints the code and `npm run type-check` checks types without a full build.

**With MySQL connected:**

```bash
timonel new nextjs my-app --with-db
timonel start my-app
# Visit: http://my-app.localhost
```

This creates the `my_app` database and user in the shared MySQL service (starting MySQL first if it isn't running) and wires the container to it with:

- `DB_HOST=mysql`
- `DB_NAME=my_app` (underscores)
- `DB_USER=my_app`
- `DB_PASSWORD=my_app`
- Waits for MySQL to be healthy before starting (`depends_on`)

Without the flag, the project starts with no database connection — useful for pure frontend practice. `--with-db` works the same way for `vite` and `parcel` projects.

> **Using an existing/downloaded project instead of scaffolding a new one?** Use `timonel add` — see [Bringing In Existing Projects](#-bringing-in-existing-projects) below. It never forces TypeScript (or anything else) onto the project.

#### WordPress Project

```bash
timonel new wp my-site
timonel start my-site
# Visit: http://my-site.localhost
```

Downloads WordPress, creates the `my_site` database and user (starting MySQL first if needed), generates `wp-config.php`, and sets up an empty theme folder at `wp-content/themes/my-site/`. Re-running `timonel new wp my-site` on an existing site is safe: it only adds what's missing and never touches your theme.

#### Vite + React Project

```bash
timonel new vite my-vite
timonel start my-vite
# Visit: http://my-vite.localhost
```

Creates a **TypeScript** React app with Vite's official scaffolder (`react-ts` template), run inside a temporary Node container, so you don't need Node.js or npm installed. `vite.config.ts` is adjusted so the dev server works inside Docker.

#### Parcel + React Project

```bash
timonel new parcel my-parcel
timonel start my-parcel
# Visit: http://my-parcel.localhost
```

A small **JavaScript** React starter built with Parcel: `public/index.html`, `src/`, `components/App/`, an `assets/` folder for static files, and Prettier (`npm run format`).

#### Laravel Project

```bash
timonel new laravel my-api                 # plain Laravel (Blade + Vite)
timonel new laravel my-app --kit react     # or vue, svelte, livewire
timonel start my-api
# Visit: http://my-api.localhost
```

Creates the project with Composer inside a temporary container (no PHP or Composer needed on your machine). With `--kit`, you get one of Laravel's official starter kits (login, registration and a dashboard already built), from their current main branch, as Laravel's own installer does. Then Timonel:

- writes `.env` for the shared services: **MySQL** (database `my_api`, instead of Laravel's SQLite default), **Mailpit** for mail, and `APP_URL=http://my-api.localhost`
- sets `QUEUE_CONNECTION=sync`, so queued jobs (like queued emails) run immediately: no queue worker runs locally, and with Laravel's default (`database`) they would wait in the `jobs` table forever. To test real background queues, set it back to `database` and run `php artisan queue:work` inside `timonel dev`
- sets up `vite.config` so Vite's dev server works inside Docker (hot reload on `localhost:5173`)
- creates the database, generates the app key, runs the migrations, and builds the front-end assets

---

### 📥 Bringing In Existing Projects

Downloaded a project (e.g. a course repo or a client site)? Put it in `apps/<name>` and run:

```bash
timonel add my-course-app            # Node projects: add --with-db for a database
timonel start my-course-app
# Visit: http://my-course-app.localhost
```

`add` detects the framework (Next.js, Vite, Parcel, WordPress, Laravel) and **asks you to confirm it**: press Enter to accept, or pick another from the list. Then it only adds what's **missing** for Docker, and never overwrites or restructures the project's own files:

- `Dockerfile`, `.dockerignore` (and a `Caddyfile` for WordPress) are added only if they don't exist.
- Your `package.json`, TypeScript-or-not setup, and source files stay exactly as downloaded.
- WordPress: a database is created; if `wp-config.php` doesn't point at the shared MySQL server, `add` tells you which settings to use (it doesn't edit the file).

`timonel add` is also safe on a project that's already set up: it skips the question and fills in anything missing (for example a database). `timonel new` is only for **fresh** projects: if `apps/<name>` already exists, it stops and points you to `add`.

---

### 💻 Dev Mode

One command for every project: `timonel dev <name>` opens a shell inside the project's container, with hints for its framework. It recognises the framework by itself.

#### WordPress (with Vite)

```bash
# Enter dev mode (also publishes port 5173 for Vite HMR)
timonel dev my-site

# Inside container (you start in the theme folder):
  npm install    - Install theme dependencies
  npm run dev    - Start Vite dev server (with HMR)
  npm run build  - Build for production

# When done: exit (port 5173 is released again)
```

Port 5173 is only published while dev mode is open, so several WordPress (and Laravel) projects can run at the same time — just one of them in dev mode at a time.

**Your theme location:** `apps/my-site/wp-content/themes/my-site/`

#### Laravel (with Vite)

```bash
# Enter dev mode (also publishes port 5173 for Vite HMR)
timonel dev my-api

# Inside container (you start in /app):
  php artisan <command>  - Artisan (migrate, make:model, tinker...)
  composer install       - Install PHP dependencies
  npm run dev            - Start Vite dev server (hot reload at localhost:5173)
  npm run build          - Build assets for production

# When done: exit (port 5173 is released again)
```

The page keeps working without `npm run dev` (it uses the built assets); while it runs, Laravel switches to the dev server automatically.

#### Next.js / Vite / Parcel

```bash
# Enter dev mode (starts the container if needed)
timonel dev my-app

# Inside container (you start in /app):
📦 Installing new packages (the dev server keeps running):
  npm install <package>  - Install package
  # If the app doesn't pick it up: exit, then
  # timonel stop my-app && timonel start my-app
  # Don't kill the dev server: it's the container's main process,
  # so the container would stop with it.

🔧 Other commands:
  npm run build        - Build for production
  npm run lint         - Lint code (Next.js; Vite if the project defines it)
  npm run type-check   - Check TypeScript types without building (Next.js)
  npm run format       - Format code with Prettier (Parcel)

# When done: exit
```

---

### 🛠️ Managing Projects

```bash
timonel up              # Start the shared services (Traefik, MySQL, Adminer, Mailpit)
timonel down            # Stop everything, projects included
timonel list            # List all projects with type and status
timonel open <name>     # Open project in VS Code
timonel start <name>    # Start project
timonel stop <name>     # Stop project
timonel restart <name>  # Restart and reinstall dependencies (Node: fresh node_modules; Laravel: composer + npm install)
timonel logs [name]     # Follow logs (one project, or everything)
timonel remove <name>   # Remove project completely (container, its volumes and image, folder; asks before deleting its database)
timonel hosts           # Write the project names into /etc/hosts (only if Safari or a tool needs it)
```

Projects don't start with `timonel up`; start each one with `timonel start <name>` (or `dev`, which starts it if needed). Every command accepts the folder name or the URL form of a project (`my_app` or `my-app`), and rejects options it doesn't know instead of ignoring them.

---

## 📂 Project Structure

```
timonel/
├── timonel                      # Main CLI script
├── install.sh                      # Installation script
├── docker-compose.yml              # Active config (git-ignored)
├── docker-compose.yml.example      # Template
├── timonel-completion.bash      # Bash autocomplete
├── timonel-completion.zsh       # Zsh autocomplete
├── scripts/
│   ├── templates/                  # Project templates
│   │   ├── stacks/
│   │   │   ├── node/               # Shared Dockerfile + .dockerignore for every Node project
│   │   │   └── php/                # Shared FrankenPHP image + Caddyfile for WordPress and Laravel
│   │   ├── nextjs/                 # Next.js starter files (package.json, tsconfig.json, page.tsx, layout.tsx...)
│   │   ├── parcel/                 # Parcel + React starter files
│   │   ├── vite/                   # (scaffolded by Vite's own tool)
│   │   └── wordpress/
│   │       ├── timonel-mailpit.php  # Must-use plugin: WordPress mail -> Mailpit
│   │       └── wp-config.php.template
│   ├── lib/
│   │   ├── compose.sh              # Read/edit docker-compose.yml (insert, list projects, labels)
│   │   ├── frameworks.sh           # Per-framework settings: stack, port, volumes, dev flags, web root
│   │   ├── laravel.sh              # Laravel .env and Vite helpers
│   │   └── project.sh              # Shared helpers: name validation, folder lookup
│   ├── add-project.sh              # `add` command: dockerize an existing project in apps/
│   ├── add-to-compose.sh           # Add any project (Next.js, Vite, Parcel, WordPress) to compose
│   ├── create-db.sh                # Create a MySQL database + user (starts MySQL if needed)
│   ├── drop-db.sh                  # Delete a project's database + user (used by remove)
│   ├── dev-mode-node.sh            # Dev mode for Next.js/Vite/Parcel (called by dev-project.sh)
│   ├── dev-mode-php.sh             # Dev mode for WordPress/Laravel (called by dev-project.sh)
│   ├── dev-project.sh              # `dev` command: picks the right dev mode for the project
│   ├── list-projects.sh            # List all projects
│   ├── new-nextjs.sh               # Create Next.js project
│   ├── new-laravel.sh              # Create Laravel project (plain or --kit)
│   ├── new-parcel.sh               # Create Parcel project
│   ├── new-vite-react.sh           # Create Vite React project
│   ├── new-wordpress.sh            # Create WordPress project
│   ├── open-project.sh             # Open project in VS Code
│   ├── remove-from-compose.sh      # Remove project from compose
│   ├── remove-project.sh           # Delete project completely
│   ├── restart-project.sh          # Restart a project, reinstalling dependencies
│   ├── setup-laravel.sh            # Laravel: composer/npm install, key, migrations (one-off container)
│   ├── start-project.sh            # Start a project
│   ├── stop-project.sh             # Stop a project
│   └── sync-hosts.sh               # Sync /etc/hosts file
└── apps/                           # Your projects (git-ignored)
```

---

## 🗄️ Database Info

### WordPress and Laravel Projects

Each WordPress or Laravel project automatically gets the following when it's created with `new` or brought in with `add` (MySQL is started first if it isn't running):

- **Database**: `project_name` (underscores)
- **User**: `project_name`
- **Password**: `project_name`
- **Host**: `mysql`

WordPress gets them in `wp-config.php`; Laravel in `.env` (`DB_CONNECTION=mysql`, `DB_HOST=mysql`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).

### Next.js, Vite and Parcel Projects

Database wiring is **opt-in** via the `--with-db` flag on `new` or `add` — not automatic like WordPress and Laravel. Same naming convention applies:

- **Database**: `project_name` (underscores)
- **User**: `project_name`
- **Password**: `project_name`
- **Host**: `mysql`

Access all databases via Adminer: http://timonel-adminer.localhost

`timonel remove` asks whether to delete a project's database too; pressing Enter keeps it.

---

## 🔧 Troubleshooting

### Port 80 Already in Use

```bash
# Check what's using port 80
lsof -i :80

# Stop other Docker projects
docker compose down
```

### Can't Access project.localhost

```bash
# 1. Is the container running?
timonel list

# 2. Safari or a command-line tool? Write the names into /etc/hosts
timonel hosts

# 3. Check the Traefik dashboard
open http://localhost:8080
```

### WordPress or Laravel Can't Connect to Database

```bash
# Wait ~30 seconds for MySQL to be healthy
docker compose ps

# Check MySQL logs
timonel logs mysql
```

If the database itself is missing, for example because the site was created while MySQL was stopped with an older Timonel version, run `add` on the project. It's safe on a project that's already set up and only creates what's missing:

```bash
timonel add my-site                # WordPress or Laravel
timonel add my-app --with-db       # Node project with a database
```

For a Laravel project brought in with its own `.env`, check that `.env` uses `DB_HOST=mysql` and the database name above; `add` prints the exact values when it doesn't.

### Port 5173 Already in Use (WordPress / Laravel dev mode)

Only one WordPress or Laravel project can be in dev mode at a time, because Vite HMR needs port 5173. Exit the other dev-mode shell first.

WordPress projects created with older Timonel versions publish 5173 **permanently** (a `ports: - "5173:5173"` entry in their `docker-compose.yml` block). This blocks other projects from using the port even outside dev mode. Delete those two lines from that project's block; `timonel dev` now publishes the port only while dev mode is open.

### Next.js Project Has No DB Env Vars

If a Next.js project was created **before** the `--with-db` flag existed, it won't have `DB_*` environment variables or a MySQL dependency — that's expected, not a bug. Two options:

1. Remove the project and recreate it with `timonel new nextjs <name> --with-db`
2. Manually add the `environment` and `depends_on` blocks to that project's service entry in `docker-compose.yml`. For the exact shape, look at the block `scripts/add-to-compose.sh` writes with `--with-db` (the `DB_*` variables and `depends_on: mysql: condition: service_healthy`).

### Next.js Project Isn't TypeScript

Two possible reasons, both expected:

1. **Created before TypeScript became the default** — same situation as the DB flag above. Recreate it, or manually add `tsconfig.json` + convert files yourself.
2. **Brought in with `timonel add`** (e.g. a course repo) — Timonel intentionally does not force TypeScript onto projects it didn't create from scratch. See [Bringing In Existing Projects](#-bringing-in-existing-projects).

### Permission Denied Removing Files

```bash
# Docker creates files as root, use Docker to remove them
docker run --rm -v "$(pwd)":/data alpine rm -rf /data/apps/project-name
```

### First WordPress or Laravel Build is Slow

- **First PHP project**: ~2-3 minutes (installs PHP extensions, Composer and Node.js)
- **Next PHP projects**: much faster, since every WordPress and Laravel project shares the same image layers (Docker cache)
- **Reopening existing**: Instant! ⚡

---

## ⚠️ Common Mistakes

### ❌ Expecting every app to open `*.localhost` without `timonel hosts`

Chrome, Firefox and Edge open `my-app.localhost` on their own; Safari and some tools may not. If a project opens in Chrome but not elsewhere, run `timonel hosts` once (again after adding new projects).

### ❌ Editing docker-compose.yml directly

```bash
# Wrong:
nano docker-compose.yml  # ❌ Changes will be lost

# Right:
nano docker-compose.yml.example  # ✅ Edit the template
cp docker-compose.yml.example docker-compose.yml
```

### ❌ Using `new` for a project you downloaded

```bash
# Wrong:
timonel new nextjs course-app   # ❌ stops: apps/course-app already exists

# Right:
timonel add course-app          # ✅ detects the framework, keeps your code as is
```

### ❌ Not waiting for MySQL on the very first start

The first `timonel up` downloads and initialises MySQL, which takes ~30 seconds. Projects that need it wait for it automatically; Adminer may show a connection error until then.

---

## 🤝 Contributing

Contributions welcome! Fork, create a feature branch, and open a PR.

### Ideas for Contributions

- [ ] Laravel queue worker and scheduler
- [ ] GUI dashboard (web-based)
- [ ] Backup/restore functionality
- [ ] Windows support (WSL2)
- [ ] PostgreSQL support

---

## 📄 License

MIT - see [LICENSE](LICENSE) file

---

## 💬 Support

- 🐛 **Bug reports**: [Open an issue](https://github.com/elenagoto/dockerator/issues)
- 💡 **Feature requests**: [Open an issue](https://github.com/elenagoto/dockerator/issues)

---

## 🙏 Acknowledgments

- **devner** by [MarJC5](https://github.com/MarJC5) - The inspiration
- **[Traefik](https://traefik.io/)** - Dynamic reverse proxy
- **[FrankenPHP](https://frankenphp.dev/)** - Modern PHP application server

---

**Made with ❤️ for efficient local development**

If this project helped you, give it a ⭐️!
