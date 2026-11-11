#!/bin/bash

# Remove a project completely
# Usage: ./remove-project.sh <project-name>

set -e

source scripts/lib/project.sh

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

# Resolve the folder BEFORE the service is removed from docker-compose.yml,
# since the folder name is read from the service's build context
# (folder my_app <-> service my-app)
APP_DIR_NAME=$(resolve_app_dir_name "$PROJECT_NAME")
if ! is_valid_project_name "$APP_DIR_NAME"; then
    echo -e "${RED}❌ Error: Unexpected folder '$APP_DIR_NAME' in docker-compose.yml, refusing to delete${NC}"
    exit 1
fi
APP_DIR="apps/$APP_DIR_NAME"

echo -e "${RED}🗑️  Removing project: $PROJECT_NAME${NC}"
echo ""

# Safety confirmation
read -p "Are you sure you want to remove '$PROJECT_NAME'? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Cancelled."
    exit 0
fi

# ============================================
# STEP 1: Check and stop container
# ============================================
# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^dockerator_$SAFE_NAME$"; then
    echo -e "${YELLOW}⚠️  Container is running, stopping...${NC}"
    docker-compose stop "$SAFE_NAME"
    echo -e "${GREEN}✅ Container stopped${NC}"
else
    echo -e "${BLUE}ℹ️  Container not running${NC}"
fi

# Remove container if it exists (even if stopped)
if docker ps -a --format '{{.Names}}' | grep -q "^dockerator_$SAFE_NAME$"; then
    echo -e "${YELLOW}⚠️  Removing container...${NC}"
    docker-compose rm -f "$SAFE_NAME"
    echo -e "${GREEN}✅ Container removed${NC}"
fi

# ============================================
# STEP 2: Remove from docker-compose.yml
# ============================================
if grep -q "^  $SAFE_NAME:" docker-compose.yml; then
    ./scripts/remove-from-compose.sh "$PROJECT_NAME"
else
    echo -e "${BLUE}ℹ️  Not in docker-compose.yml${NC}"
fi

# ============================================
# STEP 3: Remove app folder
# ============================================
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠️  Removing $APP_DIR...${NC}"
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Folder removed${NC}"
else
    echo -e "${BLUE}ℹ️  Folder doesn't exist${NC}"
fi

# ============================================
# STEP 4: Remind about /etc/hosts
# ============================================
echo ""
echo -e "${BLUE}📋 Final cleanup:${NC}"

if grep -q "$SAFE_NAME.localhost" /etc/hosts 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Remove from /etc/hosts:${NC}"
    echo "   127.0.0.1 $SAFE_NAME.localhost"
    echo ""
    echo "   Run: sudo nano /etc/hosts"
else
    echo -e "${GREEN}✅ Not in /etc/hosts${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Project '$PROJECT_NAME' removed!${NC}"