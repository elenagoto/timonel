# Dockerator 🐳

> A Docker orchestration CLI tool for managing multiple Next.js and WordPress projects with automatic routing and zero configuration.

Inspired by [devner](https://github.com/MarJC5/devner).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ✨ Features

- 🚀 **One-command project creation** - `dockerator new nextjs|wp|vite <name>`
- 🗄️ **Shared services** - MySQL, Adminer, Mailpit across all projects
- 🔌 **Opt-in DB wiring** - `--with-db` flag connects Next.js projects to MySQL on demand
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
- **Node.js & npm** installed (for Vite project scaffolding) ([Download](https://nodejs.org/))

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

---

## 📖 Usage

### Creating Projects

#### Next.js Project

```bash
dockerator new nextjs my-app
dockerator hosts
dockerator start my-app
# Visit: http://my-app.localhost
```

**With MySQL connected:**

```bash
dockerator new nextjs my-app --with-db
dockerator hosts
dockerator start my-app
# Visit: http://my-app.localhost
```

This wires the container to the shared MySQL service with:

- `DB_HOST=mysql`
- `DB_NAME=my_app` (underscores)
- `DB_USER=my_app`
- `DB_PASSWORD=my_app`
- Waits for MySQL to be healthy before starting (`depends_on`)

Without the flag, the project starts with no database connection — useful for pure frontend practice.

#### WordPress Project

```bash
dockerator new wp my-site
dockerator hosts
dockerator start my-site
# Visit: http://my-site.localhost
```

### Vite/React Project

```bash
dockerator new vite my-vite
dockerator hosts
dockerator start my-vite
# Visit: http://my-vite.localhost
```

---

### 🎨 WordPress Development with Vite

```bash
# Enter dev mode (exposes port 5173 for Vite HMR)
dockerator dev-wp my-site

# Inside container:
📦 Installing new packages:
  1. pkill -f 'next dev'    - Stop dev server
  2. npm install <package>  - Install package
  3. npm run dev            - Restart dev server

🔧 Other commands:
  npm run build  - Build for production
  npm run lint   - Lint code

# When done: exit
```

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
📦 Installing new packages:
  1. pkill -f 'next dev'    - Stop dev server
  2. npm install <package>  - Install package
  3. npm run dev            - Restart dev server

🔧 Other commands:
  npm run build  - Build for production
  npm run lint   - Lint code

# When done: exit
```

---

### 🛠️ Managing Projects

```bash
dockerator list            # List all projects with status
dockerator open <name>     # Open project in VS Code
dockerator start <name>    # Start project
dockerator stop <name>     # Stop project
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
│   │   ├── nextjs/
│   │   │   ├── .dockerignore
│   │   │   ├── .gitkeep
│   │   │   └── Dockerfile
│   │   ├── vite/
│   │   │   ├── .dockerignore
│   │   │   └── Dockerfile
│   │   └── wordpress/
│   │       ├── .gitkeep
│   │       ├── Caddyfile
│   │       ├── Dockerfile
│   │       └── wp-config.php.template
│   ├── add-to-compose-nextjs.sh           # Add NextJS project to compose
│   ├── add-to-compose-vite.sh      # Add Vite project to compose
│   ├── add-to-compose-wp.sh        # Add WordPress to compose
│   ├── dev-mode-frontend.sh        # Enter Next.js/Vite dev mode
│   ├── dev-mode-wp.sh              # Enter WordPress dev mode
│   ├── list-projects.sh            # List all projects
│   ├── new-nextjs.sh               # Create Next.js project
│   ├── new-vite-react.sh           # Create Vite React project
│   ├── new-wordpress.sh            # Create WordPress project
│   ├── open-project.sh             # Open project in VS Code
│   ├── remove-from-compose.sh      # Remove project from compose
│   ├── remove-project.sh           # Delete project completely
│   ├── start-project.sh            # Start a project
│   ├── stop-project.sh             # Stop a project
│   └── sync-hosts.sh               # Sync /etc/hosts file
└── apps/                           # Your projects (git-ignored)
```

---

## 🗄️ Database Info

### WordPress Projects

Each WordPress site automatically gets:

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

### Next.js Project Has No DB Env Vars

If a Next.js project was created **before** the `--with-db` flag existed, it won't have `DB_*` environment variables or a MySQL dependency — that's expected, not a bug. Two options:

1. Remove the project and recreate it with `dockerator new nextjs <name> --with-db`
2. Manually add the `environment` and `depends_on` blocks to that project's service entry in `docker-compose.yml` (see the Next.js block in `docker-compose.yml.example` as a reference for the shape)

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
- [ ] `dockerator restart <project>` command
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
