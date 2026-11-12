#!/bin/bash

# Remove a project completely
# Usage: ./remove-project.sh <project-name>
#
# Asks first (remove? and, if the project has one, delete its database too?),
# then removes: the container with its anonymous volumes (node_modules,
# .next...), its built image, optionally the database + user, its block in
# docker-compose.yml, and the apps/ folder.

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh

PROJECT_NAME=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

# Re-checked here (not only in the dispatcher) because this script runs rm -rf
if ! is_valid_project_name "$PROJECT_NAME" || is_reserved_project_name "$PROJECT_NAME"; then
    echo -e "${RED}❌ Error: Invalid or reserved project name '$PROJECT_NAME'${NC}"
    exit 1
fi

SAFE_NAME=$(to_safe_name "$PROJECT_NAME")

# Read everything that depends on the compose block BEFORE removing it:
# - the folder (from the build context; folder my_app <-> service my-app)
# - the database name (DB_NAME env, present for PHP and --with-db projects)
# - the built image name
APP_DIR_NAME=$(resolve_app_dir_name "$PROJECT_NAME")
if ! is_valid_project_name "$APP_DIR_NAME"; then
    echo -e "${RED}❌ Error: Unexpected folder '$APP_DIR_NAME' in docker-compose.yml, refusing to delete${NC}"
    exit 1
fi
APP_DIR="apps/$APP_DIR_NAME"

IN_COMPOSE=false
DB_NAME=""
IMAGE=""
if project_service_exists "$SAFE_NAME"; then
    IN_COMPOSE=true
    DB_NAME=$(service_label "$SAFE_NAME" DB_NAME)
    IMAGE=$(docker compose --profile projects config --images "$SAFE_NAME" 2>/dev/null || true)
fi

if [ "$IN_COMPOSE" = false ] && [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Error: No project '$PROJECT_NAME' (not in docker-compose.yml, no $APP_DIR folder)${NC}"
    exit 1
fi

echo -e "${RED}🗑️  Removing project: $PROJECT_NAME${NC}"
echo ""

# ============================================
# Questions first, then act
# ============================================
read -r -p "Are you sure you want to remove '$PROJECT_NAME' and delete $APP_DIR? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Cancelled."
    exit 0
fi

DROP_DB=false
if [ -n "$DB_NAME" ]; then
    read -r -p "Also delete its database '$DB_NAME' and user? (y/N): " answer || answer=""
    case "$answer" in
        y|Y) DROP_DB=true ;;
    esac
fi
echo ""

# ============================================
# STEP 1: Stop and remove the container + its anonymous volumes
# ============================================
if docker ps -a --format '{{.Names}}' | grep -qx "timonel_$SAFE_NAME"; then
    # -s stop if running, -f no prompt, -v anonymous volumes (node_modules...)
    docker compose --profile projects rm -fsv "$SAFE_NAME"
    echo -e "${GREEN}✅ Container and its volumes removed${NC}"
else
    echo -e "${BLUE}ℹ️  No container${NC}"
fi

# ============================================
# STEP 2: Remove the built image
# ============================================
if [ -n "$IMAGE" ] && docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker image rm "$IMAGE" >/dev/null
    echo -e "${GREEN}✅ Image $IMAGE removed${NC}"
else
    echo -e "${BLUE}ℹ️  No built image${NC}"
fi

# ============================================
# STEP 3: Database (only if you said yes)
# ============================================
if [ "$DROP_DB" = true ]; then
    ./scripts/drop-db.sh "$DB_NAME"
elif [ -n "$DB_NAME" ]; then
    echo -e "${BLUE}ℹ️  Database '$DB_NAME' kept${NC}"
fi

# ============================================
# STEP 4: Remove from docker-compose.yml
# ============================================
if [ "$IN_COMPOSE" = true ]; then
    ./scripts/remove-from-compose.sh "$PROJECT_NAME"
else
    echo -e "${BLUE}ℹ️  Not in docker-compose.yml${NC}"
fi

# ============================================
# STEP 5: Remove app folder
# ============================================
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Folder $APP_DIR removed${NC}"
else
    echo -e "${BLUE}ℹ️  Folder doesn't exist${NC}"
fi

# ============================================
# STEP 6: /etc/hosts
# ============================================
if grep -q "$SAFE_NAME.localhost" /etc/hosts 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}⚠️  $SAFE_NAME.localhost is still in /etc/hosts.${NC}"
    echo "   Run: timonel hosts   (rebuilds the list from the remaining projects)"
fi

echo ""
echo -e "${GREEN}🎉 Project '$PROJECT_NAME' removed!${NC}"
