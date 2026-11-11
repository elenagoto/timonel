#!/bin/bash

# Helpers for reading and editing the generated docker-compose.yml.
# Source this file, don't run it:
#   source scripts/lib/compose.sh
# Paths default to docker-compose.yml in the current directory (the
# `dockerator` dispatcher cd's to the repo root before running scripts).

# Shared services defined by docker-compose.yml.example (not projects)
DOCKERATOR_CORE_SERVICES="traefik mysql adminer mailpit"

# Print the name of every project service, one per line.
# Only reads keys directly under the top-level `services:` section, so
# entries under `volumes:` or `networks:` (e.g. the `dockerator` network)
# are never mistaken for projects. Core services are matched exactly, so a
# project with "mysql" inside its name is still listed.
list_project_services() {
    local file="${1:-docker-compose.yml}"
    [ -f "$file" ] || return 0
    awk -v core=" $DOCKERATOR_CORE_SERVICES " '
        # A top-level key (column 0, not a comment) starts a new section
        /^[^ \t#]/ { in_services = ($0 ~ /^services:[ \t\r]*$/); next }
        in_services && /^  [A-Za-z0-9_.-]+:[ \t\r]*$/ {
            name = $0
            sub(/^  /, "", name)
            sub(/:[ \t\r]*$/, "", name)
            if (index(core, " " name " ") == 0) print name
        }
    ' "$file"
}

# Insert the contents of a service-block file into docker-compose.yml,
# right before the first top-level `volumes:` or `networks:` key (or at the
# end of the file if there is neither).
# Unlike a `while read` loop, awk also keeps a last line that has no
# trailing newline. The file is rewritten in place, keeping its permissions.
insert_service_block() {
    local block="$1" file="${2:-docker-compose.yml}" out
    out=$(mktemp)
    if ! awk -v blockfile="$block" '
        function dump(    l) {
            while ((getline l < blockfile) > 0) print l
            close(blockfile)
            inserted = 1
        }
        !inserted && /^(volumes|networks):[ \t\r]*$/ { dump() }
        { print }
        END { if (!inserted) dump() }
    ' "$file" > "$out"; then
        rm -f "$out"
        return 1
    fi
    cat "$out" > "$file"
    rm -f "$out"
}
