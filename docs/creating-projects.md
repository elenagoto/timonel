# Creating projects

[Documentation](README.md) › Creating projects

`timonel new <type> <name>` creates a fresh project in `apps/<name>` from a template, and registers it so it runs at `http://<name>.localhost`. Then start it:

```bash
timonel new <type> <name>
timonel start <name>
```

`new` only creates **new** projects: if `apps/<name>` already exists, it stops and points you to [`timonel add`](existing-projects.md).

| Type | You get | Database |
| --- | --- | --- |
| `nextjs` | Next.js with TypeScript and ESLint | with `--with-db` |
| `vite` | React + TypeScript, created with Vite's own scaffolder | with `--with-db` |
| `parcel` | A small React starter (JavaScript) built with Parcel | with `--with-db` |
| `wp` | WordPress, with an empty theme folder | always |
| `laravel` | Laravel, optionally with a starter kit | always |

## Next.js

```bash
timonel new nextjs my-app
```

A **TypeScript** app (strict mode) using the App Router: `src/app/page.tsx`, `src/app/layout.tsx`, `tsconfig.json`, and `eslint.config.mjs` with Next's recommended rules (the same setup `create-next-app` gives you). In [dev mode](dev-mode.md), `npm run lint` lints the code and `npm run type-check` checks types without a full build.

## Vite + React

```bash
timonel new vite my-vite
```

A **TypeScript** React app from Vite's official `react-ts` template. The scaffolder runs in a temporary Node container, so Node.js isn't needed on your machine. `vite.config.ts` is adjusted so the dev server works inside Docker.

## Parcel + React

```bash
timonel new parcel my-parcel
```

A small **JavaScript** React starter: `public/index.html`, `src/`, `components/App/`, an `assets/` folder for static files, and Prettier (`npm run format`).

## WordPress

```bash
timonel new wp my-site
```

Downloads the latest WordPress, creates the `my_site` database and user, generates `wp-config.php`, and sets up an empty theme folder at `wp-content/themes/my-site/`. Mail sent by WordPress goes to [Mailpit](databases-and-mail.md#mail). Open <http://my-site.localhost> to run the WordPress installer.

## Laravel

```bash
timonel new laravel my-api                 # plain Laravel (Blade + Vite)
timonel new laravel my-app --kit react     # or: vue, svelte, livewire
```

The project is created with Composer in a temporary container (no PHP or Composer needed on your machine). With `--kit`, you get one of Laravel's official starter kits, with login, registration and a dashboard already built, from the kit's current version (as Laravel's own installer does).

Timonel then prepares it for the shared services:

- `.env` uses **MySQL** (database `my_api`) instead of Laravel's SQLite default, **Mailpit** for mail, and `APP_URL=http://my-api.localhost`
- `QUEUE_CONNECTION=sync`, so queued jobs (such as queued emails) run right away. No queue worker runs locally; with Laravel's default (`database`), they would never run. See [Databases and mail](databases-and-mail.md#laravel-queues).
- `vite.config` is adjusted so Vite's dev server works inside Docker (hot reload on `localhost:5173`)
- the app key is generated, the migrations run, and the front-end assets are built

## Connecting a Node project to MySQL

Next.js, Vite and Parcel projects have no database unless you ask for one:

```bash
timonel new nextjs my-app --with-db
```

This creates the `my_app` database and user (starting MySQL if needed) and gives the container these environment variables:

```text
DB_HOST=mysql
DB_NAME=my_app
DB_USER=my_app
DB_PASSWORD=my_app
```

The project also waits for MySQL to be ready before starting. Decide when creating the project: adding a database to an existing Node project later means editing its block in `docker-compose.yml` by hand (see [Troubleshooting](troubleshooting.md#a-node-project-needs-a-database-after-all)).

## Names and addresses

The name you give becomes the folder (`apps/my_app`, exactly as typed) and the address (`http://my-app.localhost`, lowercase with hyphens). The rules are in [Getting started](getting-started.md#project-names).
