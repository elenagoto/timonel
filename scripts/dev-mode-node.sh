#!/bin/bash

# Development mode for a Node project (Next.js, Vite, Parcel)
# Usage: ./dev-mode-node.sh <project-name> <framework>
# Normally called through dev-project.sh (the `dev` command).
#
# Starts the container if needed and opens a shell in /app. The dev server
# keeps running as the container's main process.

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

PROJECT_NAME=$1
FRAMEWORK=$2
SAFE_NAME=$(to_safe_name "$PROJECT_NAME")

# Colors
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$PROJECT_NAME" ] || [ -z "$FRAMEWORK" ]; then
    echo -e "${RED}❌ Usage: dev-mode-node.sh <project-name> <framework>${NC}"
    exit 1
fi

if ! project_service_exists "$SAFE_NAME"; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found${NC}"
    exit 1
fi

# Start the container if it isn't running
if ! docker ps --format '{{.Names}}' | grep -qx "dockerator_$SAFE_NAME"; then
    echo -e "${YELLOW}⚠️  Container not running. Starting...${NC}"
    docker-compose --profile projects up -d "$SAFE_NAME"
    sleep 2
fi

echo -e "${BLUE}🚀 Entering development environment for $PROJECT_NAME ($(framework_setting "$FRAMEWORK" display))...${NC}"
echo ""
echo "📦 Installing new packages (the dev server keeps running):"
echo "  npm install <package>   - Install package (package.json updates on your machine too)"
echo "  If the app doesn't pick it up: exit, then"
echo "    dockerator stop $SAFE_NAME && dockerator start $SAFE_NAME"
echo "  ⚠️  Don't kill the dev server: it is the container's main process,"
echo "     so the container (and this shell) would stop with it."
echo ""
echo "🔧 Other commands:"
case "$FRAMEWORK" in
    next)
        echo "  npm run build        - Build for production"
        echo "  npm run lint         - Lint code"
        echo "  npm run type-check   - Check TypeScript types without building"
        ;;
    vite)
        echo "  npm run build        - Build for production"
        echo "  npm run lint         - Lint code (if the project defines it)"
        ;;
    parcel)
        echo "  npm run build        - Build for production"
        echo "  npm run format       - Format code with Prettier (if the project defines it)"
        ;;
esac
echo ""
echo -e "${YELLOW}Type 'exit' when done${NC}"
echo ""

# Enter the container at /app
docker-compose exec "$SAFE_NAME" sh
