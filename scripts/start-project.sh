#!/bin/bash

# Start a specific project
# Usage: ./start-project.sh <project-name>

set -e

PROJECT_NAME=$1
source scripts/lib/project.sh
source scripts/lib/compose.sh

SAFE_URL=$(to_safe_name "$PROJECT_NAME")

# Colors
GREEN='\033[0;32m'
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

echo -e "${BLUE}🚀 Starting $PROJECT_NAME...${NC}"

# Start the specific service
docker compose --profile projects up -d "$SAFE_URL"

echo -e "${GREEN}✅ $PROJECT_NAME started${NC}"
echo ""
echo "Access at: http://$SAFE_URL.localhost"