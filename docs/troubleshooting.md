# Troubleshooting

[Documentation](README.md) › Troubleshooting

## First: what did the command say?

If a command failed earlier and its output is gone from your terminal, Timonel kept a copy:

```bash
timonel history            # the last 20 commands, ✓ or ✗
timonel history --errors   # the last 5 failed ones, with their full output
```

See [the command log](commands.md#the-command-log).

## A project doesn't open at `http://<name>.localhost`

1. Is it running? `timonel list` shows each project's status; start it with `timonel start <name>`.
2. Is it still starting? The first start installs the project's packages and can take a minute or two. Follow it with `timonel logs <name>`.
3. Does it open in Chrome but not in Safari or a command-line tool? Run `timonel hosts` once ([why](getting-started.md#do-i-need-timonel-hosts)).
4. Check the Traefik dashboard at <http://localhost:8080>: every running project should appear as a router.

## `timonel up` fails: port already in use

Timonel needs ports 80, 8080, 3306 and 1025 on your machine. Another program (a local MySQL, another Docker setup, a web server) may be using one. Find it, for example for port 80:

```bash
lsof -nP -iTCP:80 -sTCP:LISTEN
```

Stop that program, or its containers, then run `timonel up` again.

## WordPress or Laravel can't connect to the database

1. MySQL needs a moment after the very first `timonel up` (it initialises its data). Projects wait for it automatically; Adminer may show an error until then.
2. Check MySQL's logs: `timonel logs mysql`.
3. If the project's database is missing, run `timonel add <name>`. On a project that's already set up, it only creates what's missing.
4. A project brought in with its **own** `wp-config.php` or `.env` must point at the shared server. `add` prints the exact values when it doesn't; see [Databases and mail](databases-and-mail.md#names-and-credentials).

## Port 5173 is already in use in dev mode

Only one WordPress or Laravel project can be in [dev mode](dev-mode.md#port-5173-for-wordpress-and-laravel) at a time, because Vite's dev server needs port 5173. Exit the other project's dev shell first.

## A new package isn't picked up

In a Next.js, Vite or Parcel project, after `npm install <package>` in dev mode, restart the project: `timonel stop <name> && timonel start <name>`. If dependencies are in a bad state, `timonel restart <name>` reinstalls them from scratch.

## A Node project needs a database after all

The database is chosen when the project is created (`--with-db`). To add one later:

1. Create the database: `timonel add <name> --with-db`. On a registered project this creates the database and user, but doesn't change how the project is started.
2. Give the project the connection settings, either in its own configuration (for example a `.env` file with `DB_HOST=mysql` and the values from [Databases and mail](databases-and-mail.md#names-and-credentials)), or by adding the `environment` and `depends_on` entries to its block in `docker-compose.yml`, in the same shape that `--with-db` writes.

## A Next.js project isn't TypeScript

Projects brought in with `timonel add` keep whatever setup they came with: Timonel doesn't convert them. Only projects created with `timonel new nextjs` start as TypeScript.

## The first WordPress or Laravel start is slow

The first PHP project builds the shared PHP image (PHP extensions, Composer, Node.js), which takes a few minutes. Every later WordPress or Laravel project reuses it, so they start much faster.

## Permission denied when deleting files (Linux)

Files created by a container can belong to `root` on Linux. Delete them through Docker, from the `timonel` folder:

```bash
docker run --rm -v "$(pwd)/apps":/apps alpine rm -rf /apps/<name>
```

On macOS this doesn't happen.

## Editing `docker-compose.yml`

`docker-compose.yml` is generated: `new`, `add` and `remove` edit it for you, and it isn't part of the repository. Avoid editing it by hand, except for small per-project tweaks you're prepared to redo.

> **Don't re-copy the template over it** (`cp docker-compose.yml.example docker-compose.yml`): that replaces the whole file, and every registered project disappears from it. Changes to the shared services belong in `docker-compose.yml.example`, and only apply to a fresh install.

## Using `new` for a project you downloaded

`timonel new nextjs course-app` stops if `apps/course-app` already exists, so you can't overwrite a downloaded project by mistake. Use `timonel add course-app` instead: it detects the framework and keeps your code as it is. See [Bringing in existing projects](existing-projects.md).
