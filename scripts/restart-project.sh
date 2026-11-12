#!/bin/bash

# Restart a project with a full dependency reinstall
# Usage: ./restart-project.sh <project-name>
#
# A plain `docker-compose restart` (or even `up --build`) does NOT reinstall
# npm dependencies: node_modules lives in an anonymous volume that Compose
# reuses across restarts by default. This rebuilds the image without cache
# and discards that anonymous volume so `npm install` actually runs again.
# (Scope: meaningful for nextjs/vite/parcel projects; WordPress theme deps
# aren't affected since they don't use this volume pattern.)

set -e

PROJECT_NAME=$1
source scripts/lib/project.sh
source scripts/lib/compose.sh

SAFE_URL=$(to_safe_name "$PROJECT_NAME")

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

# Check if project exists in docker-compose.yml
if ! project_service_exists "$SAFE_URL"; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Restarting $PROJECT_NAME with a full dependency reinstall...${NC}"
echo ""

# STEP 1: Rebuild without cache, so RUN npm install runs from scratch
echo -e "${BLUE}📦 Rebuilding image (no cache)...${NC}"
docker-compose build --no-cache "$SAFE_URL"
echo -e "${GREEN}✅ Image rebuilt${NC}"

# STEP 2: Recreate the container AND discard its anonymous volumes
# --renew-anon-volumes is what actually drops the stale node_modules
echo -e "${BLUE}🔁 Recreating container with fresh volumes...${NC}"
docker-compose --profile projects up -d --force-recreate --renew-anon-volumes "$SAFE_URL"
echo -e "${GREEN}✅ Container recreated${NC}"

echo ""
echo -e "${GREEN}🎉 $PROJECT_NAME restarted, dependencies reinstalled${NC}"
echo ""
echo "Access at: http://$SAFE_URL.localhost"