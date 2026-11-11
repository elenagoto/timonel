#!/bin/bash

# Shared project-name helpers. Source this file, don't run it:
#   source scripts/lib/project.sh
# Functions read docker-compose.yml from the current directory, so callers
# must run from the dockerator root (the `dockerator` dispatcher cd's there).

# Names Dockerator itself uses in docker-compose.yml (core services and the
# network key). A project with one of these names would collide with them.
DOCKERATOR_RESERVED_NAMES="traefik mysql adminer mailpit dockerator"

# Lowercase, '_' -> '-': the form used for compose service keys, container
# names and hostnames.
to_safe_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-'
}

# Letters, digits, '-' and '_' only, starting with a letter or digit.
# Rules out '.', '..', '/', spaces and shell/sed/SQL metacharacters.
is_valid_project_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]
}

is_reserved_project_name() {
    local safe reserved
    safe=$(to_safe_name "$1")
    for reserved in $DOCKERATOR_RESERVED_NAMES; do
        [ "$safe" = "$reserved" ] && return 0
    done
    return 1
}

# Print the project's folder name under apps/, given either the folder name
# or the compose service name. The folder keeps the name as typed at creation
# (e.g. "my_app" or "MyApp") while the service is sanitized ("my-app",
# "myapp"), so the folder is read from the service's build context.
# Falls back to the name as given when the service isn't in the compose file.
resolve_app_dir_name() {
    local name="$1" safe dir
    safe=$(to_safe_name "$name")
    dir=$(awk -v svc="  $safe:" -v q="'" '
        { line = $0; sub(/[ \t\r]+$/, "", line) }
        line == svc { found = 1; next }
        # The block ends at the next line indented 0-2 spaces
        found && match($0, /[^ \t\r]/) && RSTART <= 3 { exit }
        found && /^[ \t]+context:/ {
            sub(/^[ \t]+context:[ \t]*/, "")
            sub(/[ \t\r]+$/, "")
            gsub(/"/, ""); gsub(q, "")
            if (sub(/^\.\/apps\//, "")) { sub(/\/$/, ""); print }
            exit
        }
    ' docker-compose.yml 2>/dev/null)
    if [ -n "$dir" ]; then
        echo "$dir"
    else
        echo "$name"
    fi
}
