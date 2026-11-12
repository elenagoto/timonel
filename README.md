# Timonel 🧭

> Run many local projects side by side in Docker (Next.js, Vite, Parcel, WordPress, Laravel), each at its own `http://<name>.localhost` address, with a shared MySQL, Adminer and Mailpit. Create new projects, or drop in ones you downloaded.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platforms: macOS and Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
[![Documentation](https://img.shields.io/badge/docs-elenagoto.github.io%2Ftimonel-indigo)](https://elenagoto.github.io/timonel/)

**Formerly known as Dockerator.** *Timonel* is Spanish for *helmsman*: the one who steers the ship, as this tool steers your local projects. Old links to the Dockerator repository still lead here.

**📖 Documentation: <https://elenagoto.github.io/timonel/>** (also readable in [`docs/`](docs/README.md))

---

## Features

- 🚀 **One-command projects**: `timonel new nextjs|vite|parcel|wp|laravel <name>`, Laravel with optional starter kits
- 📥 **Bring your own project**: `timonel add <name>` runs a downloaded project without touching its code
- 🧑‍💻 **One dev command**: `timonel dev <name>` opens a shell in any project, with hints for its framework
- 🐳 **Only Docker needed**: no Node.js, npm, PHP or Composer on your machine; even the scaffolders run in containers
- 🗄️ **Shared services**: MySQL, Adminer and Mailpit for every project; databases set up automatically for WordPress and Laravel
- 🔄 **Hot reload** everywhere, including Vite in WordPress themes and Laravel
- 📜 **Command log**: `timonel history` shows what you ran and why something failed
- ⚡ **Tab completion** for commands and project names

## Quick start

Requires Docker (Desktop or Engine with the Compose plugin) on macOS or Linux.

```bash
git clone https://github.com/elenagoto/timonel.git
bash timonel/install.sh          # links the `timonel` command, sets up tab completion

# in a new terminal window:
timonel up                       # start the shared services
timonel new nextjs my-app        # create a project
timonel start my-app             # → http://my-app.localhost
```

## Documentation

| | |
| --- | --- |
| [Getting started](docs/getting-started.md) | Install, shared services, first project, uninstall |
| [Creating projects](docs/creating-projects.md) | `new` for Next.js, Vite, Parcel, WordPress and Laravel |
| [Bringing in existing projects](docs/existing-projects.md) | `add` for projects you already have |
| [Dev mode](docs/dev-mode.md) | Working inside a project: packages, tools, hot reload |
| [Databases and mail](docs/databases-and-mail.md) | MySQL, Adminer, Mailpit, Laravel queues |
| [Commands](docs/commands.md) | Every command and option |
| [Troubleshooting](docs/troubleshooting.md) | When something doesn't work |
| [How it works](docs/how-it-works.md) | For contributors: architecture and conventions |

## Contributing

Contributions are welcome: fork the repository, create a branch and open a pull request. [How it works](docs/how-it-works.md) explains the architecture, and how to add a framework or preview the documentation. Bugs and ideas: [open an issue](https://github.com/elenagoto/timonel/issues).

## License and credits

[MIT](LICENSE) © 2025-2026 Laura Gomez.

Inspired by devner by [MarJC5](https://github.com/MarJC5). Built on [Traefik](https://traefik.io/) and [FrankenPHP](https://frankenphp.dev/). Documentation site made with [Zensical](https://zensical.org/).
