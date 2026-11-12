# Commands

[Documentation](README.md) › Commands

All commands, at a glance. `timonel help` prints the same list.

```bash
timonel <command> [arguments]
```

Wherever a command takes a project `<name>`, both forms work: the folder name (`my_app`) or the address form (`my-app`). Options a command doesn't know are rejected, never silently ignored.

## Shared services

| Command | What it does |
| --- | --- |
| `timonel up` | Start Traefik, MySQL, Adminer and Mailpit. Projects don't start with it: start them one by one. |
| `timonel down` | Stop everything, projects included. |

## Projects

| Command | What it does |
| --- | --- |
| `timonel new <type> <name>` | Create a new project. Types: `nextjs`, `vite`, `parcel`, `wp`, `laravel`. See [Creating projects](creating-projects.md). |
| `timonel add <name>` | Run a project that's already in `apps/<name>`. See [Bringing in existing projects](existing-projects.md). |
| `timonel start <name>` | Start a project (the first start installs its packages and takes longer). |
| `timonel stop <name>` | Stop a project. |
| `timonel restart <name>` | Restart a project and reinstall its dependencies. See [Dev mode](dev-mode.md#reinstalling-everything). |
| `timonel dev <name>` | Open a shell inside the project. See [Dev mode](dev-mode.md). |
| `timonel list` | List all projects with their type, status and address. |
| `timonel logs [name]` | Follow a project's logs, or everything's without a name. `Ctrl+C` to stop. |
| `timonel open <name>` | Open the project in VS Code (WordPress: its theme folder). |
| `timonel remove <name>` | Remove a project completely (see below). |

## Other

| Command | What it does |
| --- | --- |
| `timonel hosts` | Write the project names into `/etc/hosts`, for Safari and tools that don't resolve `*.localhost` themselves. Asks for your password. See [Getting started](getting-started.md#do-i-need-timonel-hosts). |
| `timonel history` | Show the last 20 commands you ran, with ✓ or ✗ and how long they took. See below. |
| `timonel history --errors` | Show the last 5 failed commands, with everything they printed. |
| `timonel help` | Show the command list. |

## Options

| Option | Commands | What it does |
| --- | --- | --- |
| `--with-db` | `new` (Node types), `add` | Create a MySQL database for a Next.js, Vite or Parcel project and connect the project to it. WordPress and Laravel always get one. |
| `--kit <kit>` | `new laravel` | Create the project from one of Laravel's starter kits: `react`, `vue`, `svelte` or `livewire`. |

## What `remove` deletes

`timonel remove <name>` asks first, then deletes:

- the project's container, with its cached `node_modules` and build folders
- the project's built image
- its registration in `docker-compose.yml`
- the project folder `apps/<name>`, **including your code**

If the project has a database, it also asks whether to delete it. Pressing Enter keeps it.

> **Back up first** if the folder holds work you want to keep (commit and push it, or copy it elsewhere).

## The command log

Every `timonel` command is recorded in `logs/timonel.log`, inside the Timonel folder: when it ran, the full command, what it printed (without colours) and how it ended. `timonel history` and `timonel history --errors` read it for you.

- `dev` and `logs` only record when they started and ended, not their output.
- `help` and `history` aren't recorded.
- A command stopped with `Ctrl+C` is shown as interrupted.
- The log keeps the last 5,000 lines, so it never grows large.

The log stays on your computer: it isn't part of the repository.
