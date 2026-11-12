# Timonel documentation

Timonel runs many local projects side by side in Docker (Next.js, Vite, Parcel, WordPress, Laravel), each at its own `http://<name>.localhost` address, with a shared MySQL, Adminer and Mailpit. Only Docker is needed on your machine.

## Start here

- **[Getting started](getting-started.md)**: install Timonel, start the shared services, create your first project.

## Guides

| You want to… | Read |
| --- | --- |
| Create a new project from a template | [Creating projects](creating-projects.md) |
| Run a project you already have (a course repo, a client site) | [Bringing in existing projects](existing-projects.md) |
| Work inside a project: install packages, run tools, hot reload | [Dev mode](dev-mode.md) |
| Use the database or check sent emails | [Databases and mail](databases-and-mail.md) |
| Look up a command or option | [Commands](commands.md) |
| Fix something that doesn't work | [Troubleshooting](troubleshooting.md) |

## For contributors

- **[How it works](how-it-works.md)**: how the stacks, templates and scripts fit together, and how to add a framework.

---

This documentation is also published as a website at <https://elenagoto.github.io/timonel/>.
