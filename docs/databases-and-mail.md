# Databases and mail

[Documentation](README.md) › Databases and mail

All projects share one MySQL 8.4 server and one Mailpit mail catcher, started by `timonel up`.

## Databases

### Which projects get one

| Projects | Database |
| --- | --- |
| WordPress, Laravel | Always, created by `new` or `add` |
| Next.js, Vite, Parcel | Only with `--with-db` (on `new` or `add`) |

MySQL is started automatically when a database is created, if it isn't running yet.

### Names and credentials

Each project gets its own database and user, all three named after the project, with underscores:

| | Project `my-app` |
| --- | --- |
| Database | `my_app` |
| User | `my_app` |
| Password | `my_app` |
| Host (from inside Docker) | `mysql` |

Where a project finds them:

- **WordPress:** in `wp-config.php`
- **Laravel:** in `.env` (`DB_CONNECTION=mysql`, `DB_HOST=mysql`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`)
- **Next.js, Vite, Parcel** (with `--with-db`): environment variables `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`

### Browsing the databases

- **In the browser:** Adminer at <http://timonel-adminer.localhost>. Server `mysql`, user `root`, password `timonel`.
- **With a desktop app** (TablePlus, Sequel Ace…): host `127.0.0.1`, port `3306`, user `root`, password `timonel`. This only works from your own computer, not from other devices on your network.

### Removing a database

`timonel remove <name>` asks whether to delete the project's database and user too. Pressing Enter keeps them, so you can still open the data in Adminer later.

## Mail

Every email your projects send is caught by **Mailpit**, so nothing reaches real inboxes. Read them at <http://timonel-mailpit.localhost>.

- **WordPress:** set up automatically, through a small must-use plugin (`timonel-mailpit.php`) that sends WordPress mail to Mailpit.
- **Laravel:** set up automatically in `.env` (`MAIL_MAILER=smtp`, `MAIL_HOST=mailpit`, `MAIL_PORT=1025`).
- **Other apps:** use SMTP host `mailpit`, port `1025`, no authentication or encryption. An app running outside Docker on your computer uses `127.0.0.1:1025`.

## Laravel queues

New Laravel projects get `QUEUE_CONNECTION=sync` in `.env`: queued jobs, like queued emails, run immediately during the request. That's because no **queue worker** runs locally; with Laravel's default (`database`), queued jobs would wait in the `jobs` table forever and, for example, queued emails would never reach Mailpit.

To test real background queues, set `QUEUE_CONNECTION=database` in `.env`, then run the worker in [dev mode](dev-mode.md):

```bash
timonel dev my-api
php artisan queue:work
```

The scheduler works the same way: run `php artisan schedule:work` in dev mode while you need it.
