#!/bin/bash

# List all Dockerator projects
# Usage: ./list-projects.sh

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📋 Dockerator Projects${NC}"
echo ""

# Get running services (matched exactly per project below, so core
# services in this list don't matter)
RUNNING=$(docker-compose ps --services --filter "status=running" 2>/dev/null || true)

# Project services only: keys under `services:`, minus the core services
ALL_SERVICES=$(list_project_services)

if [ -z "$ALL_SERVICES" ]; then
    echo -e "${YELLOW}No projects found${NC}"
    echo ""
    echo "Create one with:"
    echo "  dockerator new nextjs <name>"
    echo "  dockerator new wp <name>"
    exit 0
fi

# Header
echo -e "${BLUE}PROJECT              TYPE           STATUS           URL${NC}"
echo "────────────────────────────────────────────────────────────────────────"

# Display projects
for project in $ALL_SERVICES; do
    # The folder can differ from the service name (folder my_app, service my-app)
    dir="apps/$(resolve_app_dir_name "$project")"

    # Skip if not a real project directory
    if [ ! -d "$dir" ]; then
        continue
    fi

    # Determine type: the framework label written by add-to-compose.sh,
    # else guess from files (WordPress and projects created before labels)
    FRAMEWORK=$(service_label "$project" dockerator.framework)
    if [ -n "$FRAMEWORK" ]; then
        TYPE_NAME=$(framework_setting "$FRAMEWORK" display 2>/dev/null || echo "$FRAMEWORK")
    elif [ -f "$dir/artisan" ]; then
        TYPE_NAME="Laravel"
    elif [ -f "$dir/wp-config.php" ]; then
        TYPE_NAME="WordPress"
    elif [ -f "$dir/vite.config.js" ] || [ -f "$dir/vite.config.ts" ]; then
        TYPE_NAME="Vite"
    elif [ -f "$dir/.parcelrc" ]; then
        TYPE_NAME="Parcel"
    elif [ -f "$dir/package.json" ]; then
        TYPE_NAME="Next.js"
    else
        TYPE_NAME="Unknown"
    fi
    case "$TYPE_NAME" in
        WordPress) TYPE_COLOR=$CYAN ;;
        Laravel)   TYPE_COLOR=$RED ;;
        Vite)      TYPE_COLOR=$YELLOW ;;
        Next.js)   TYPE_COLOR=$GREEN ;;
        Parcel)    TYPE_COLOR=$MAGENTA ;;
        *)         TYPE_COLOR=$NC ;;
    esac

    # Check status (exact match)
    if echo "$RUNNING" | grep -qx -- "$project"; then
        STATUS_DOT="${GREEN}●${NC}"
        STATUS_TEXT="Running"
    else
        STATUS_DOT="○"
        STATUS_TEXT="Stopped"
    fi

    # URL
    URL="http://$project.localhost"

    # Pad the plain text, then wrap it in colour codes, so columns line up
    printf "%-20s %b%-14s%b %b %-14s %s\n" \
        "$project" "$TYPE_COLOR" "$TYPE_NAME" "$NC" "$STATUS_DOT" "$STATUS_TEXT" "$URL"
done

echo ""
echo "Commands:"
echo "  dockerator start <project>             - Start a specific project"
echo "  dockerator stop <project>              - Stop a specific project"
echo "  dockerator dev-wp <project>            - Enter WordPress dev mode (with Vite)"
echo "  dockerator dev-nextjs <project>        - Enter Next.js dev mode"
echo "  dockerator dev-vite <project>          - Enter Vite React dev mode"
echo "  dockerator dev-front <project>         - Enter Frontend dev mode (for vite & nextjs)"
echo "  dockerator logs <project>              - View project logs"
echo "  dockerator open <project>              - Open in VS Code"
echo ""