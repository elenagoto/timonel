#!/bin/bash

# Per-framework settings: the one place that says how each framework runs.
# Source this file, don't run it:
#   source scripts/lib/frameworks.sh
#
# Written as a `case` function rather than an associative array because
# macOS ships bash 3.2, which has no associative arrays.
#
# Usage: framework_setting <framework> <key>
# Keys:
#   stack          node | php
#   port           port the dev server listens on inside the container
#                  (Traefik routes <name>.localhost to it)
#   cache_volumes  container paths shadowed by anonymous volumes, so the
#                  host's node_modules / build caches never clobber the
#                  container's (space-separated)
#   dev_args       extra arguments for `npm run dev --` (empty if none)
#   display        human-readable name for `list`
#
# Adding a Node framework = adding its lines here (plus a template folder
# if it can be scaffolded with `new`).

framework_setting() {
    case "$1:$2" in
        next:stack|vite:stack|parcel:stack)  echo "node" ;;

        next:port)    echo "3000" ;;
        vite:port)    echo "5173" ;;
        parcel:port)  echo "1234" ;;

        next:cache_volumes)    echo "/app/node_modules /app/.next" ;;
        vite:cache_volumes)    echo "/app/node_modules" ;;
        parcel:cache_volumes)  echo "/app/node_modules" ;;

        # Vite only listens on localhost by default, which Traefik can't reach
        vite:dev_args)  echo "--host 0.0.0.0" ;;
        next:dev_args|parcel:dev_args)  echo "" ;;

        next:display)    echo "Next.js" ;;
        vite:display)    echo "Vite" ;;
        parcel:display)  echo "Parcel" ;;

        *) return 1 ;;
    esac
}

KNOWN_FRAMEWORKS="next vite parcel"

is_known_framework() {
    framework_setting "$1" stack >/dev/null 2>&1
}
