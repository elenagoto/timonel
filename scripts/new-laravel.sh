#!/bin/bash

# Create a new Laravel project
# Usage: ./new-laravel.sh <project-name> [kit]
#   kit: react | vue | svelte | livewire  (Laravel's starter kits, with
#        login/registration already built). Without it: the plain
#        laravel/laravel skeleton (Blade + Vite).
#
# Like Laravel's own installer, but nothing needs to be installed on your
# machine: Composer runs in a throwaway container, the rest in the
# project's own image.

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/laravel.sh

APP_NAME=$1
KIT=$2
APP_DIR="apps/$APP_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$APP_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

case "$KIT" in
    "")                         PACKAGE="laravel/laravel";            STABILITY="" ;;
    react|vue|svelte|livewire)  PACKAGE="laravel/$KIT-starter-kit";   STABILITY="--stability=dev" ;;
    *)
        echo -e "${RED}❌ Unknown starter kit '$KIT' (react, vue, svelte, livewire)${NC}"
        exit 1
        ;;
esac

SAFE_NAME=$(to_safe_name "$APP_NAME")
SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

echo -e "${BLUE}Creating Laravel project: $APP_NAME${KIT:+ ($KIT starter kit)}${NC}"
echo ""

# ============================================
# STEP 1: Create the project with Composer (throwaway container)
# ============================================
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠️  Folder $APP_DIR already exists, skipping create-project${NC}"
else
    mkdir -p apps
    echo -e "${BLUE}📦 composer create-project $PACKAGE (in a temporary container)...${NC}"
    # Starter kits are installed from their main branch (--stability=dev),
    # exactly as Laravel's installer does. --no-scripts: key, database and
    # migrations are set up below, against MySQL instead of SQLite.
    # As your user so the files stay yours.
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -e COMPOSER_HOME=/tmp/composer \
        -v "$PWD/apps:/apps" \
        -w /apps \
        composer:2 \
        create-project --no-interaction --prefer-dist --no-scripts $STABILITY "$PACKAGE" "$APP_NAME"
    echo -e "${GREEN}✅ Created $APP_DIR${NC}"
fi

# ============================================
# STEP 2: Docker files (shared PHP stack)
# ============================================
for file in Dockerfile .dockerignore Caddyfile; do
    if [ ! -f "$APP_DIR/$file" ]; then
        cp "scripts/templates/stacks/php/$file" "$APP_DIR/"
        echo -e "${GREEN}✅ Created $file${NC}"
    else
        echo -e "${YELLOW}⚠️  $file already exists${NC}"
    fi
done

# ============================================
# STEP 3: .env wired to MySQL + Mailpit, Vite reachable from Docker
# ============================================
if [ "$(laravel_create_env "$APP_DIR" "$SAFE_NAME" "$SAFE_DB")" = "created" ]; then
    echo -e "${GREEN}✅ Created .env (MySQL, Mailpit, APP_URL=http://$SAFE_NAME.localhost)${NC}"
else
    echo -e "${YELLOW}⚠️  .env already exists, kept as is${NC}"
fi

case "$(laravel_patch_vite "$APP_DIR")" in
    patched) echo -e "${GREEN}✅ Configured Vite for Docker (dev server on localhost:5173)${NC}" ;;
    already) echo -e "${YELLOW}⚠️  Vite config already has an hmr setting, kept as is${NC}" ;;
    *)       echo -e "${YELLOW}⚠️  Couldn't find a vite.config to configure for Docker${NC}" ;;
esac

# ============================================
# STEP 4: Database + docker-compose.yml
# ============================================
echo ""
./scripts/create-db.sh "$SAFE_DB"

echo ""
if project_service_exists "$SAFE_NAME"; then
    echo -e "${YELLOW}⚠️  Already in docker-compose.yml${NC}"
else
    ./scripts/add-to-compose.sh "$APP_NAME" laravel
fi

# ============================================
# STEP 5: App key, migrations, front-end build (inside the project image)
# ============================================
echo ""
./scripts/setup-laravel.sh "$APP_NAME" --migrate

echo ""
echo -e "${GREEN}🎉 Laravel project '$APP_NAME' ready!${NC}"
echo ""
echo "Database: $SAFE_DB (user $SAFE_DB, password $SAFE_DB) on the shared MySQL"
echo ""
echo "Next steps:"
echo "  1. Start container: timonel start $SAFE_NAME"
echo "  2. Visit: http://$SAFE_NAME.localhost"
echo "  3. Dev shell (artisan, npm run dev with hot reload): timonel dev $SAFE_NAME"
