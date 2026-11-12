# Getting started

[Documentation](README.md) › Getting started

## Requirements

- **Docker Desktop** (or Docker Engine with the Compose plugin), installed and running. [Download Docker Desktop](https://www.docker.com/products/docker-desktop).
- **macOS or Linux**.

That's all: Node.js, npm, PHP and Composer are **not** needed on your machine. Every project runs in a container, and even the tools that create new projects run in temporary containers.

Check that Docker is running:

```bash
docker info --format '{{.ServerVersion}}'
```

## Install

```bash
git clone https://github.com/elenagoto/timonel.git
bash timonel/install.sh
```

The installer:

- links the `timonel` command into `/usr/local/bin` (it asks for your password only if that folder isn't writable for you)
- sets up tab completion for zsh or bash (a marked block in `~/.zshrc` or `~/.bashrc`)
- creates `docker-compose.yml` from the template
- removes leftovers of an older `dockerator` install, if any

It can be run from any folder, and again at any time: it only does what's missing. Then **open a new terminal window**, so the command and tab completion are picked up, and check:

```bash
timonel help
```

## Start the shared services

```bash
timonel up
```

This starts four containers shared by all your projects:

| Service | Address | What for |
| --- | --- | --- |
| Traefik | <http://localhost:8080> (dashboard) | Routes `http://<name>.localhost` to the right project |
| MySQL 8.4 | `mysql` inside Docker, `127.0.0.1:3306` from your Mac | One database per project (user `root`, password `timonel`) |
| Adminer | <http://timonel-adminer.localhost> | Browse and edit the databases in your browser |
| Mailpit | <http://timonel-mailpit.localhost> | Catches every email your projects send |

The first `timonel up` downloads the images and initialises MySQL, which takes a minute. The Traefik dashboard, MySQL and Mailpit's mail port only accept connections from your own computer, not from other devices on your network.

## Create your first project

```bash
timonel new nextjs my-app
timonel start my-app
```

Open <http://my-app.localhost>. The first start takes a minute (it installs the project's packages); later starts are quick.

Other project types: `vite`, `parcel`, `wp` (WordPress) and `laravel`. See [Creating projects](creating-projects.md). Already have a project? See [Bringing in existing projects](existing-projects.md).

When you're done for the day:

```bash
timonel down     # stops the shared services and all projects
```

## Do I need `timonel hosts`?

Usually not. Chrome, Firefox and Edge open any `*.localhost` address on their own. Safari and some command-line tools may not: if a project opens in Chrome but not there, run this once (and again after adding projects):

```bash
timonel hosts    # writes the project names into /etc/hosts; asks for your password
```

## Project names

Names may contain letters, digits, `-` and `_`, and must start with a letter or digit (`my-app`, `my_app`, `MyApp`). The names `traefik`, `mysql`, `adminer`, `mailpit` and `timonel` are reserved.

The project folder keeps the name exactly as you typed it (`apps/my_app`), while the address and container use a lowercase, hyphenated form (`my-app.localhost`). Every command accepts either form.

## Uninstall

```bash
timonel down                                   # stop everything
sudo rm /usr/local/bin/timonel                 # the command
rm ~/.timonel-path ~/.zsh/completion/_timonel  # completion files
```

Then delete the block between `# >>> timonel completion >>>` and `# <<< timonel completion <<<` in `~/.zshrc` (or `~/.bashrc`), and the cloned `timonel` folder (your projects are in its `apps/` folder: keep a copy first if you need them). The database volume is removed with `docker volume rm timonel_mysql_data`.
