# Bringing in existing projects

[Documentation](README.md) › Bringing in existing projects

Downloaded a project, such as a course repository or a client site? Put it in `apps/<name>` and run:

```bash
timonel add my-course-app
timonel start my-course-app
```

Then open <http://my-course-app.localhost>.

## What `add` does

1. **Detects the framework**: Next.js, Vite, Parcel, WordPress or Laravel.
2. **Asks you to confirm it.** The detected one is marked; press Enter to accept, or type another number or name. If it can't detect anything, you choose.
3. **Adds only what Docker needs**, and only if it's missing: `Dockerfile` and `.dockerignore` (plus a `Caddyfile` for WordPress and Laravel).
4. **Creates the database**: always for WordPress and Laravel; for Node projects only with `--with-db`.
5. **Registers the project**, so it runs at `http://<name>.localhost`.

```bash
timonel add my-course-app --with-db    # Node project that needs MySQL
```

## What `add` never touches

Your code stays exactly as downloaded: `package.json`, source files, TypeScript or not. If the project already has its own `Dockerfile`, it's kept.

The only things `add` may create are files that are local configuration rather than code:

- **WordPress:** a small must-use plugin that sends WordPress mail to Mailpit, if missing. If `wp-config.php` doesn't point at the shared MySQL server, `add` prints the settings to use; it doesn't edit the file.
- **Laravel:** a `.env` built from `.env.example` (MySQL, Mailpit, `APP_URL`), only if there is none. If an existing `.env` doesn't use the shared MySQL server, `add` prints the values to use. Then it installs what's missing (`vendor/`, app key, `node_modules/`, built assets), and runs the migrations only when it just created the `.env`. For Vite hot reload inside Docker, it prints the `vite.config` setting to add, rather than editing your config.

## Running `add` again

`add` is safe on a project that's already set up: it skips the question and only fills in what's missing, for example a database that wasn't created. It never changes the project's registration.

## `new` or `add`?

| The folder `apps/<name>`… | Use |
| --- | --- |
| doesn't exist yet | `timonel new <type> <name>` ([Creating projects](creating-projects.md)) |
| already exists | `timonel add <name>` |

`new` refuses a folder that already exists, so you can't overwrite a downloaded project by mistake.

Tab completion helps here: `timonel add <Tab>` suggests the folders in `apps/` that aren't registered yet.
