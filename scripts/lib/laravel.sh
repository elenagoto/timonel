#!/bin/bash

# Laravel helpers. Source this file, don't run it:
#   source scripts/lib/laravel.sh

# Set KEY=VALUE in an env file. Replaces the first line for KEY, including a
# commented-out one (`# DB_HOST=127.0.0.1` in Laravel's .env.example), or
# appends the line if KEY isn't there. Values here never contain spaces.
#   Usage: set_env_value <file> <KEY> <value>
set_env_value() {
    local file="$1" key="$2" value="$3" tmp
    tmp=$(mktemp)
    awk -v key="$key" -v value="$value" '
        !done && $0 ~ "^#?[ \t]*" key "=" { print key "=" value; done = 1; next }
        { print }
        END { if (!done) print key "=" value }
    ' "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
}

# Create the project's .env from .env.example (only if .env doesn't exist),
# wired to Dockerator's shared services:
#   MySQL instead of Laravel's SQLite default, Mailpit for mail,
#   APP_URL=http://<name>.localhost
# and QUEUE_CONNECTION=sync: queued jobs (e.g. queued mail) run right away
# during the request, because no queue worker runs. With Laravel's default
# (database) they would wait forever in the jobs table.
# Prints "created" if it wrote a new .env, nothing otherwise.
#   Usage: laravel_create_env <app_dir> <safe_name> <safe_db>
laravel_create_env() {
    local dir="$1" safe_name="$2" safe_db="$3"
    [ -f "$dir/.env" ] && return 0
    [ -f "$dir/.env.example" ] || return 0

    cp "$dir/.env.example" "$dir/.env"
    set_env_value "$dir/.env" APP_URL      "http://$safe_name.localhost"
    set_env_value "$dir/.env" DB_CONNECTION mysql
    set_env_value "$dir/.env" DB_HOST      mysql
    set_env_value "$dir/.env" DB_PORT      3306
    set_env_value "$dir/.env" DB_DATABASE  "$safe_db"
    set_env_value "$dir/.env" DB_USERNAME  "$safe_db"
    set_env_value "$dir/.env" DB_PASSWORD  "$safe_db"
    set_env_value "$dir/.env" MAIL_MAILER  smtp
    set_env_value "$dir/.env" MAIL_HOST    mailpit
    set_env_value "$dir/.env" MAIL_PORT    1025
    set_env_value "$dir/.env" QUEUE_CONNECTION sync
    echo "created"
}

# Make Vite reachable from the browser when it runs inside the container:
# listen on all interfaces, on the port `dockerator dev` publishes (5173),
# and tell the browser to load assets from localhost:5173 (server.hmr.host,
# as Laravel's docs recommend for Sail). Edits vite.config.js/.ts in place,
# inside its existing `server: {` block if there is one. Idempotent: does
# nothing if the file already sets `hmr`.
# Prints "patched", "already", "missing" (no vite.config) or "unrecognised"
# (a shape it doesn't know; left untouched).
#   Usage: laravel_patch_vite <app_dir>
laravel_patch_vite() {
    local dir="$1" file tmp
    for file in "$dir/vite.config.ts" "$dir/vite.config.js" ""; do
        [ -z "$file" ] && { echo "missing"; return 0; }
        [ -f "$file" ] && break
    done
    if grep -q "hmr" "$file"; then
        echo "already"
        return 0
    fi

    # Written with \n (awk -v turns it into a newline; macOS awk rejects a
    # literal newline in a -v value)
    local settings='        host: "0.0.0.0",\n        port: 5173,\n        strictPort: true,\n        hmr: { host: "localhost" },'

    tmp=$(mktemp)
    if grep -qE '^    server:[[:space:]]*\{[[:space:]]*$' "$file"; then
        # Existing top-level server block: add the settings inside it
        awk -v settings="$settings" '
            { print }
            !done && /^    server:[ \t]*\{[ \t]*$/ { print settings; done = 1 }
        ' "$file" > "$tmp"
    elif grep -qE 'defineConfig\(\{[[:space:]]*$' "$file"; then
        # No server block: add one right after defineConfig({
        awk -v settings="$settings" '
            { print }
            !done && /defineConfig\(\{[ \t]*$/ { print "    server: {"; print settings; print "    },"; done = 1 }
        ' "$file" > "$tmp"
    else
        rm -f "$tmp"
        echo "unrecognised"
        return 0
    fi
    cat "$tmp" > "$file"
    rm -f "$tmp"
    echo "patched"
}
