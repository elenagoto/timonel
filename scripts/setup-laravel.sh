#!/bin/bash

# Finish setting up a Laravel project inside its own image
# Usage: ./setup-laravel.sh <project-name> [--migrate] [--reinstall]
#
# Runs in a one-off container of the project (docker-compose run --rm),
# as your user so the files stay yours, and only does what's missing:
#   - composer install         if vendor/ is missing
#   - php artisan key:generate if .env has no APP_KEY
#   - npm install + npm run build, if there's a package.json and
#     node_modules/ or the built assets (public/build) are missing
# Options:
#   --migrate    also run the database migrations (php artisan migrate)
#   --reinstall  always run composer install and npm install + build
#                (used by `dockerator restart`)
# MySQL must already be running (create-db.sh starts it).

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh

PROJECT_NAME=$1
shift || true
MIGRATE=false
REINSTALL=false
for arg in "$@"; do
    case "$arg" in
        --migrate)   MIGRATE=true ;;
        --reinstall) REINSTALL=true ;;
        *) echo "❌ Unknown option: $arg"; exit 1 ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SAFE_NAME=$(to_safe_name "$PROJECT_NAME")
if ! project_service_exists "$SAFE_NAME"; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found in docker-compose.yml${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 Setting up Laravel inside the container (first run builds the image)...${NC}"

# Steps run inside the container (in /app, the project folder)
SETUP='
set -e
if [ "$REINSTALL" = true ] || [ ! -d vendor ]; then
    echo "📦 composer install"
    composer install --no-interaction --prefer-dist
fi
if ! grep -qE "^APP_KEY=.+" .env 2>/dev/null; then
    echo "🔑 php artisan key:generate"
    php artisan key:generate --ansi
fi
if [ "$MIGRATE" = true ]; then
    echo "🗄️  php artisan migrate"
    php artisan migrate --force --ansi
fi
if [ -f package.json ]; then
    if [ "$REINSTALL" = true ] || [ ! -d node_modules ]; then
        echo "📦 npm install"
        npm install --no-audit --no-fund
    fi
    if [ "$REINSTALL" = true ] || [ ! -d public/build ]; then
        echo "🏗️  npm run build"
        npm run build
    fi
fi
'

# --no-deps: MySQL is already running (and a project container may be too)
docker-compose --profile projects run --rm --no-deps \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e COMPOSER_HOME=/tmp/composer \
    -e MIGRATE="$MIGRATE" \
    -e REINSTALL="$REINSTALL" \
    "$SAFE_NAME" sh -c "$SETUP"

echo -e "${GREEN}✅ Laravel setup done${NC}"
