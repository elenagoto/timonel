#!/bin/bash

# Development mode for a PHP project (WordPress, Laravel)
# Usage: ./dev-mode-php.sh <project-name> [framework]
# Normally called through dev-project.sh (the `dev` command), which passes
# the framework; without it, the framework is looked up here.
#
# Publishes port 5173 (Vite HMR) for this project only while dev mode is open.
# The port is added through a temporary compose override file, so
# docker-compose.yml is never edited. On exit the container is recreated
# without the port, freeing 5173 for other projects.

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

PROJECT_NAME=$1
FRAMEWORK=$2
SAFE_URL=$(to_safe_name "$PROJECT_NAME")
VITE_PORT=5173

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

# Check if project exists
if ! project_service_exists "$SAFE_URL"; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found in docker-compose.yml${NC}"
    exit 1
fi

# The folder can differ from the service name (folder my_site, service my-site)
APP_DIR_NAME=$(resolve_app_dir_name "$PROJECT_NAME")

# Framework: passed in by dev-project.sh, else label or files
if [ -z "$FRAMEWORK" ]; then
    FRAMEWORK=$(project_framework "$PROJECT_NAME" || true)
fi

if [ "$(framework_setting "$FRAMEWORK" stack 2>/dev/null)" != "php" ]; then
    echo -e "${RED}❌ Error: '$PROJECT_NAME' is not a PHP project (WordPress/Laravel)${NC}"
    echo "   Use: timonel dev $PROJECT_NAME"
    exit 1
fi

# Where the shell opens
case "$FRAMEWORK" in
    wordpress) WORK_DIR="/app/wp-content/themes/$APP_DIR_NAME" ;;  # the project's theme
    *)         WORK_DIR="/app" ;;
esac

echo -e "${BLUE}🔧 Setting up development environment for $PROJECT_NAME ($(framework_setting "$FRAMEWORK" display))...${NC}"

# Projects created by older Timonel versions publish 5173 permanently in
# docker-compose.yml. Don't add it a second time for those.
ALREADY_PUBLISHED=$(awk -v svc="  $SAFE_URL:" -v port="$VITE_PORT:$VITE_PORT" '
    { line = $0; sub(/[ \t\r]+$/, "", line) }
    line == svc { found = 1; next }
    found && match($0, /[^ \t\r]/) && RSTART <= 3 { exit }
    found && index($0, port) { print "yes"; exit }
' docker-compose.yml)

OVERRIDE_DIR=""

cleanup() {
    if [ -n "$OVERRIDE_DIR" ]; then
        echo ""
        echo -e "${BLUE}🧹 Cleaning up: recreating container without port $VITE_PORT...${NC}"
        # Same config minus the override -> Compose recreates the container
        docker-compose --profile projects up -d "$SAFE_URL" || \
            echo -e "${YELLOW}⚠️  Could not recreate container; run: timonel start $SAFE_URL${NC}"
        rm -rf "$OVERRIDE_DIR"
    fi
    echo -e "${GREEN}✅ Development mode ended${NC}"
}
trap cleanup EXIT

if [ "$ALREADY_PUBLISHED" = "yes" ]; then
    echo -e "${GREEN}✅ Port $VITE_PORT already published for $PROJECT_NAME${NC}"
    docker-compose --profile projects up -d "$SAFE_URL"
else
    echo -e "${BLUE}📝 Publishing Vite port ($VITE_PORT) for $PROJECT_NAME...${NC}"
    OVERRIDE_DIR=$(mktemp -d)
    cat > "$OVERRIDE_DIR/dev.override.yml" << EOF
services:
  $SAFE_URL:
    ports:
      - "$VITE_PORT:$VITE_PORT"
EOF
    # Recreates the container with the extra port (starts it if stopped)
    docker-compose -f docker-compose.yml -f "$OVERRIDE_DIR/dev.override.yml" \
        --profile projects up -d "$SAFE_URL"
fi

echo -e "${GREEN}✅ Container ready${NC}"
echo ""
echo -e "${BLUE}📂 Entering development environment...${NC}"
echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"
echo ""
echo "Available commands:"
case "$FRAMEWORK" in
    laravel)
        echo "  php artisan <command>  - Artisan (migrate, make:model, tinker...)"
        echo "  composer install       - Install PHP dependencies"
        echo "  npm install            - Install front-end dependencies"
        echo "  npm run dev            - Start Vite dev server (with HMR)"
        echo "  npm run build          - Build assets for production"
        ;;
    *)
        echo "  npm install    - Install theme dependencies"
        echo "  npm run dev    - Start Vite dev server (with HMR)"
        echo "  npm run build  - Build for production"
        ;;
esac
echo ""
echo -e "${YELLOW}Type 'exit' when done to cleanup${NC}"
echo ""

# Enter the container at the working directory
docker-compose exec "$SAFE_URL" sh -c "cd '$WORK_DIR' && exec sh"
