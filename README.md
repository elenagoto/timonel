# Dockerator 🐳

> A Docker orchestration CLI tool for managing multiple Next.js and WordPress projects with automatic routing and zero configuration.

Inspired by [devner](https://github.com/MarJC5/devner).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ✨ Features

- 🚀 **One-command project creation** - `dockerator new nextjs|wp|vite <name>`
- 📘 **TypeScript by default** - New Next.js projects scaffold as TypeScript (strict mode), not JavaScript
- 🗄️ **Shared services** - MySQL, Adminer, Mailpit across all projects
- 🔌 **Opt-in DB wiring** - `--with-db` flag connects Next.js, Vite and Parcel projects to MySQL on demand
- 🔄 **Hot reload** - Changes reflect immediately (Vite + Next.js)
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
# 1. Clone and install
git clone https://github.com/elenagoto/dockerator.git
cd dockerator
bash install.sh

# 2. Start base services
dockerator up

# 3. Sync hosts file
dockerator hosts
```

---

## 🌐 Access Services

- 🎛️ **Traefik Dashboard**: http://localhost:8080
- 🗄️ **Adminer** (Database): http://dockerator-adminer.localhost
  - Server: `mysql` | User: `root` | Pass: `dockerator`
- 📧 **Mailpit** (Email Testing): http://dockerator-mailpit.localhost
  - WordPress projects send all their mail here automatically (via a small `dockerator-mailpit.php` must-use plugin)
  - Other apps: SMTP host `mailpit`, port `1025`, no auth/TLS

---

## 📖 Usage

### Creating Projects

> **Project names** may contain letters, digits, `-` and `_`, and must start with a letter or digit (e.g. `my-app`, `my_app`, `MyApp`). The names `traefik`, `mysql`, `adminer`, `mailpit` and `dockerator` are reserved.
>
> The folder keeps the name exactly as you typed it (`apps/my_app`), while the URL and container use a lowercase, hyphenated form (`my-app.localhost`). Every command accepts either form: `dockerator open my_app` and `dockerator open my-app` both work.

#### Next.js Project

```bash
dockerator new nextjs my-app
dockerator hosts
dockerator start my-app
# Visit: http://my-app.localhost
```

Scaffolds a **TypeScript** Next.js app (strict mode) — `src/app/page.tsx`, `src/app/layout.tsx`, and a `tsconfig.json` at the project root. Run `npm run type-check` inside dev mode any time to check types without a full build.

**With MySQL connected:**

```bash
dockerator new nextjs my-app --with-db
dockerator hosts
dockerator start my-app
# Visit: http://my-app.localhost
```

This creates the `my_app` database and user in the shared MySQL service (starting MySQL first if it isn't running) and wires the container to it with:

- `DB_HOST=mysql`
- `DB_NAME=my_app` (underscores)
- `DB_USER=my_app`
- `DB_PASSWORD=my_app`
- Waits for MySQL to be healthy before starting (`depends_on`)

Without the flag, the project starts with no database connection — useful for pure frontend practice.

> **Using an existing/downloaded project instead of scaffolding a new one?** See [Bringing In Existing Projects](#-bringing-in-existing-projects) below — the TypeScript default does **not** get forced onto projects that already have their own `src/app` (e.g. course exercises).

#### WordPress Project

```bash
dockerator new wp my-site
dockerator hosts
dockerator start my-site
# Visit: http://my-site.localhost
```

Downloads WordPress, creates the `my_site` database and user (starting MySQL first if needed), generates `wp-config.php`, and sets up an empty theme folder at `wp-content/themes/my-site/`. Re-running `dockerator new wp my-site` on an existing site is safe: it only adds what's missing and never touches your theme.

### Vite/React Project

```bash
dockerator new vite my-vite
dockerator hosts
dockerator start my-vite
# Visit: http://my-vite.localhost
```

---

### 📥 Bringing In Existing Projects

If you download a project (e.g. a course repo) into `apps/<name>` and then run `dockerator new nextjs <name>` to wire up Docker, Dockerator only fills in what's **missing** — it never overwrites or restructures files that already exist:

- Already has `package.json`? Left untouched, as-is (whatever dependencies/JS-or-TS setup it already has).
- Already has `src/app`? The entire scaffolding step (including the default `tsconfig.json`) is skipped — the project stays exactly as downloaded, TypeScript or not.
- Missing `Dockerfile` / `.dockerignore`? Those get added, since Docker plumbing is Dockerator's actual job.

In short: **the TypeScript default only applies to brand-new projects scaffolded from scratch.** A downloaded plain-JS course project run through `dockerator new nextjs` stays plain JS — nothing forces a conversion.

---

### 🎨 WordPress Development with Vite

```bash
# Enter dev mode (exposes port 5173 for Vite HMR)
dockerator dev-wp my-site

# Inside container (you start in the theme folder):
  npm install    - Install theme dependencies
  npm run dev    - Start Vite dev server (with HMR)
  npm run build  - Build for production

# When done: exit (port 5173 is released again)
```

Port 5173 is only published while dev mode is open, so several WordPress projects can run at the same time — just one of them in dev mode at a time.

**Your theme location:** `apps/my-site/wp-content/themes/my-site/`

---

### 💻 Next.js/Vite Development

```bash
# Enter dev mode
dockerator dev-nextjs my-app
# or
dockerator dev-vite my-app
# or
dockerator dev-front my-app

# Inside container:
📦 Installing new packages (the dev server keeps running):
  npm install <package>  - Install package
  # If the app doesn't pick it up: exit, then
  # dockerator stop my-app && dockerator start my-app
  # Don't kill the dev server: it's the container's main process,
  # so the container would stop with it.

🔧 Other commands:
  npm run build       - Build for production
  npm run lint         - Lint code
  npm run type-check   - Check TypeScript types without building (TS projects only)

# When done: exit
```

---

### 🛠️ Managing Projects

```bash
dockerator list            # List all projects with status
dockerator open <name>     # Open project in VS Code
dockerator start <name>    # Start project
dockerator stop <name>     # Stop project
dockerator restart <name>  # Restart with a full dependency reinstall (node_modules included)
dockerator logs <name>     # View logs
dockerator remove <name>   # Remove project completely
dockerator hosts           # Sync /etc/hosts
```

---

## 📂 Project Structure

```
dockerator/
├── dockerator                      # Main CLI script
├── install.sh                      # Installation script
├── docker-compose.yml              # Active config (git-ignored)
├── docker-compose.yml.example      # Template
├── dockerator-completion.bash      # Bash autocomplete
├── dockerator-completion.zsh       # Zsh autocomplete
├── scripts/
│   ├── templates/                  # Project templates
│   │   ├── stacks/
│   │   │   ├── node/               # Shared Dockerfile + .dockerignore for every Node project
│   │   │   └── php/                # Shared FrankenPHP image + Caddyfile for WordPress and Laravel
│   │   ├── nextjs/                 # Next.js starter files (package.json, tsconfig.json, page.tsx, layout.tsx...)
│   │   ├── parcel/                 # Parcel + React starter files
│   │   ├── vite/                   # (scaffolded by Vite's own tool)
│   │   └── wordpress/
│   │       ├── dockerator-mailpit.php  # Must-use plugin: WordPress mail -> Mailpit
│   │       └── wp-config.php.template
│   ├── lib/
│   │   ├── compose.sh              # Read/edit docker-compose.yml (insert, list projects, labels)
│   │   ├── frameworks.sh           # Per-framework settings: stack, port, volumes, dev flags, web root
│   │   └── project.sh              # Shared helpers: name validation, folder lookup
│   ├── add-to-compose.sh           # Add any project (Next.js, Vite, Parcel, WordPress) to compose
│   ├── create-db.sh                # Create a MySQL database + user (starts MySQL if needed)
│   ├── dev-mode-frontend.sh        # Enter Next.js/Vite dev mode
│   ├── dev-mode-php.sh             # Enter WordPress/Laravel dev mode
│   ├── list-projects.sh            # List all projects
│   ├── new-nextjs.sh               # Create Next.js project
│   ├── new-parcel.sh               # Create Parcel project
│   ├── new-vite-react.sh           # Create Vite React project
│   ├── new-wordpress.sh            # Create WordPress project
│   ├── open-project.sh             # Open project in VS Code
│   ├── remove-from-compose.sh      # Remove project from compose
│   ├── remove-project.sh           # Delete project completely
│   ├── restart-project.sh          # Restart a project, reinstalling dependencies
│   ├── start-project.sh            # Start a project
│   ├── stop-project.sh             # Stop a project
│   └── sync-hosts.sh               # Sync /etc/hosts file
└── apps/                           # Your projects (git-ignored)
```

---

## 🗄️ Database Info

### WordPress Projects

Each WordPress site automatically gets the following when it's created (`dockerator new wp` starts MySQL itself if it isn't running):

- **Database**: `project_name` (underscores)
- **User**: `project_name`
- **Password**: `project_name`
- **Host**: `mysql`

### Next.js Projects

Database wiring is **opt-in** via the `--with-db` flag (see [Usage](#-usage) above) — not automatic like WordPress. Same naming convention applies:

- **Database**: `project_name` (underscores)
- **User**: `project_name`
- **Password**: `project_name`
- **Host**: `mysql`

Access all databases via Adminer: http://dockerator-adminer.localhost

---

## 🔧 Troubleshooting

### Port 80 Already in Use

```bash
# Check what's using port 80
lsof -i :80

# Stop other Docker projects
docker-compose down
```

### Can't Access project.localhost

```bash
# 1. Is container running?
docker-compose ps

# 2. Sync hosts file
dockerator hosts

# 3. Check Traefik dashboard
open http://localhost:8080
```

### WordPress Can't Connect to Database

```bash
# Wait ~30 seconds for MySQL to be healthy
docker-compose ps

# Check MySQL logs
dockerator logs mysql
```

If the database itself is missing, for example because the site was created while MySQL was stopped with an older Dockerator version, re-run the create command. It's safe on an existing project and only creates what's missing:

```bash
dockerator new wp my-site                # WordPress
dockerator new nextjs my-app --with-db   # Next.js with DB
```

### Port 5173 Already in Use (WordPress dev mode)

Only one WordPress project can be in `dev-wp` mode at a time, because Vite HMR needs port 5173. Exit the other dev-mode shell first.

WordPress projects created with older Dockerator versions publish 5173 **permanently** (a `ports: - "5173:5173"` entry in their `docker-compose.yml` block). This blocks other projects from using the port even outside dev mode. Delete those two lines from that project's block; `dockerator dev-wp` now publishes the port only while dev mode is open.

### Next.js Project Has No DB Env Vars

If a Next.js project was created **before** the `--with-db` flag existed, it won't have `DB_*` environment variables or a MySQL dependency — that's expected, not a bug. Two options:

1. Remove the project and recreate it with `dockerator new nextjs <name> --with-db`
2. Manually add the `environment` and `depends_on` blocks to that project's service entry in `docker-compose.yml` (see the Next.js block in `docker-compose.yml.example` as a reference for the shape)

### Next.js Project Isn't TypeScript

Two possible reasons, both expected:

1. **Created before TypeScript became the default** — same situation as the DB flag above. Recreate it, or manually add `tsconfig.json` + convert files yourself.
2. **Scaffolded from an existing/downloaded project** (e.g. a course repo) that already had its own `src/app` — Dockerator intentionally does not force TypeScript onto projects it didn't create from scratch. See [Bringing In Existing Projects](#-bringing-in-existing-projects).

### Permission Denied Removing Files

```bash
# Docker creates files as root, use Docker to remove them
docker run --rm -v "$(pwd)":/data alpine rm -rf /data/apps/project-name
```

### First WordPress Build is Slow

- **First WP project**: ~2-3 minutes (installs PHP extensions + Node.js)
- **Second WP project**: ~1 minute (uses Docker cache)
- **Reopening existing**: Instant! ⚡

---

## ⚠️ Common Mistakes

### ❌ Forgetting to sync hosts

```bash
dockerator new nextjs my-app
dockerator hosts  # ← Don't forget this!
```

### ❌ Editing docker-compose.yml directly

```bash
# Wrong:
nano docker-compose.yml  # ❌ Changes will be lost

# Right:
nano docker-compose.yml.example  # ✅ Edit the template
cp docker-compose.yml.example docker-compose.yml
```

### ❌ Not waiting for MySQL

Wait ~30 seconds after `dockerator up` before accessing WordPress sites.

---

## 🤝 Contributing

Contributions welcome! Fork, create a feature branch, and open a PR.

### Ideas for Contributions

- [ ] Laravel support
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

- **[devner](https://github.com/MarJC5/devner)** by [MarJC5](https://github.com/MarJC5) - The inspiration
- **[Traefik](https://traefik.io/)** - Dynamic reverse proxy
- **[FrankenPHP](https://frankenphp.dev/)** - Modern PHP application server

---

**Made with ❤️ for efficient local development**

If this project helped you, give it a ⭐️!
