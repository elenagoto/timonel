#!/bin/bash

# Enter development mode for a WordPress project
# Usage: ./dev-mode-wp.sh <project-name>
#
# Publishes port 5173 (Vite HMR) for this project only while dev mode is open.
# The port is added through a temporary compose override file, so
# docker-compose.yml is never edited. On exit the container is recreated
# without the port, freeing 5173 for other projects.

set -e

source scripts/lib/project.sh

PROJECT_NAME=$1
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
if ! grep -q "^  $SAFE_URL:" docker-compose.yml; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found in docker-compose.yml${NC}"
    exit 1
fi

# The theme folder is named after the project folder (which may differ from
# the service name, e.g. folder my_site vs service my-site)
THEME_DIR="/app/wp-content/themes/$(resolve_app_dir_name "$PROJECT_NAME")"

echo -e "${BLUE}🔧 Setting up development environment for $PROJECT_NAME...${NC}"

# Projects created by older Dockerator versions publish 5173 permanently in
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
            echo -e "${YELLOW}⚠️  Could not recreate container; run: dockerator start $SAFE_URL${NC}"
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
    cat > "$OVERRIDE_DIR/dev-wp.override.yml" << EOF
services:
  $SAFE_URL:
    ports:
      - "$VITE_PORT:$VITE_PORT"
EOF
    # Recreates the container with the extra port (starts it if stopped)
    docker-compose -f docker-compose.yml -f "$OVERRIDE_DIR/dev-wp.override.yml" \
        --profile projects up -d "$SAFE_URL"
fi

echo -e "${GREEN}✅ Container ready${NC}"
echo ""
echo -e "${BLUE}📂 Entering development environment...${NC}"
echo -e "${YELLOW}Theme directory: $THEME_DIR${NC}"
echo ""
echo "Available commands:"
echo "  npm run dev    - Start Vite dev server (with HMR)"
echo "  npm run build  - Build for production"
echo "  npm install    - Install dependencies"
echo ""
echo -e "${YELLOW}Type 'exit' when done to cleanup${NC}"
echo ""

# Enter the container at the theme directory
docker-compose exec "$SAFE_URL" sh -c "cd '$THEME_DIR' && exec sh"
