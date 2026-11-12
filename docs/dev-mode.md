# Dev mode

[Documentation](README.md) › Dev mode

`timonel dev <name>` opens a shell **inside** a project's container, where its tools (npm, Composer, Artisan…) are installed. It recognises the project's framework by itself and shows the commands that matter for it. Type `exit` when you're done.

You edit the code on your machine as usual, in any editor: the project folder is shared with the container, so changes show up immediately.

## Next.js, Vite and Parcel

```bash
timonel dev my-app
```

The shell opens in `/app` (your project folder). The dev server is already running as the container's main process, with hot reload.

**Installing packages:**

```bash
npm install <package>
```

`package.json` is updated on your machine too. If the app doesn't pick up the new package, exit and restart the project: `timonel stop my-app && timonel start my-app`.

> **Don't stop the dev server** from inside the shell (for example with `pkill`): it's the container's main process, so the container, and your shell, would stop with it.

**Other commands:**

| Command | Projects |
| --- | --- |
| `npm run build` | all |
| `npm run lint` | Next.js; Vite if the project defines it |
| `npm run type-check` | Next.js |
| `npm run format` | Parcel |

## WordPress

```bash
timonel dev my-site
```

The shell opens in the project's **theme folder** (`wp-content/themes/my-site/`), ready for front-end work with Vite:

| Command | What it does |
| --- | --- |
| `npm install` | Install the theme's dependencies |
| `npm run dev` | Start Vite's dev server, with hot reload |
| `npm run build` | Build the theme's assets for production |

## Laravel

```bash
timonel dev my-api
```

The shell opens in `/app`, the project root:

| Command | What it does |
| --- | --- |
| `php artisan <command>` | Artisan: `migrate`, `make:model`, `tinker`… |
| `composer install` | Install PHP dependencies |
| `npm run dev` | Start Vite's dev server, with hot reload at `localhost:5173` |
| `npm run build` | Build the assets for production |

The site keeps working without `npm run dev`, using the built assets. While `npm run dev` runs, Laravel switches to the dev server automatically.

## Port 5173 for WordPress and Laravel

Vite's dev server needs port 5173 on your machine. For WordPress and Laravel projects, `timonel dev` opens that port only while the dev shell is open, and frees it when you exit. So several WordPress and Laravel projects can run at the same time, but only **one** of them can be in dev mode at once.

Next.js, Vite and Parcel projects don't need this: their dev server is reached through `http://<name>.localhost`.

## Reinstalling everything

If dependencies get into a bad state, `timonel restart <name>` restarts the project and reinstalls them:

- **Next.js, Vite, Parcel:** rebuilds the image and starts with a fresh `node_modules`
- **Laravel:** re-runs `composer install`, `npm install` and the asset build
