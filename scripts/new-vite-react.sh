#!/bin/bash

# Create a new Vite + React + TypeScript project using Vite's official scaffolder
# Usage: ./new-vite-react.sh <project-name>
# Requires: Node.js and npm available on the host machine

set -e

APP_NAME=$1
APP_DIR="apps/$APP_NAME"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$APP_NAME" ]; then
    echo "❌ Error: Project name required"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is required but not found. Please install Node.js first."
    exit 1
fi

echo -e "${BLUE}Creating Vite + React + TypeScript project: $APP_NAME${NC}"
echo ""

# ============================================
# STEP 0: Check if app exists in docker-compose
# ============================================
SAFE_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
if grep -q "^  $SAFE_NAME:" docker-compose.yml; then
    echo -e "${YELLOW}⚠️  Project already in docker-compose.yml${NC}"
    IN_COMPOSE=true
else
    IN_COMPOSE=false
fi



# ============================================
# STEP 1: Scaffold project with Vite
# ============================================
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠️  Folder $APP_DIR already exists, skipping scaffold${NC}"
else
    mkdir -p apps
    (cd apps && npm create --yes vite@latest "$APP_NAME" -- --template react-ts --no-interactive)
    echo -e "${GREEN}✅ Scaffolded Vite + React + TypeScript project${NC}"
fi

# ============================================
# STEP 2: Patch vite.config.ts for Docker
# ============================================
VITE_CONFIG="$APP_DIR/vite.config.ts"
if [ ! -f "$VITE_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  vite.config.ts not found, skipping patch${NC}"
elif grep -q 'usePolling' "$VITE_CONFIG"; then
    # Already patched (re-run) - don't add a second server block
    echo -e "${YELLOW}⚠️  vite.config.ts already patched for Docker${NC}"
elif grep -q 'plugins: \[react()\],' "$VITE_CONFIG"; then
    # Write to a temp file instead of `sed -i`, whose syntax differs
    # between macOS (BSD) and Linux (GNU)
    sed 's/plugins: \[react()\],/plugins: [react()],\
  server: {\
    host: true,\
    port: 5173,\
    watch: {\
      usePolling: true,\
    },\
  },/' "$VITE_CONFIG" > "$VITE_CONFIG.tmp"
    mv "$VITE_CONFIG.tmp" "$VITE_CONFIG"
    echo -e "${GREEN}✅ Patched vite.config.ts for Docker${NC}"
else
    echo -e "${YELLOW}⚠️  Couldn't find 'plugins: [react()],' in vite.config.ts${NC}"
    echo "   Add this manually inside defineConfig({...}):"
    echo "   server: { host: true, port: 5173, watch: { usePolling: true } },"
fi

# ============================================
# STEP 3: Copy Dockerfile from template
# ============================================
if [ -f "$APP_DIR/Dockerfile" ]; then
    echo -e "${YELLOW}⚠️  Dockerfile already exists${NC}"
else
    cp scripts/templates/vite/Dockerfile "$APP_DIR/Dockerfile"
    echo -e "${GREEN}✅ Created Dockerfile${NC}"
fi

# ============================================
# STEP 4: Copy .dockerignore from template
# ============================================
if [ -f "$APP_DIR/.dockerignore" ]; then
    echo -e "${YELLOW}⚠️  .dockerignore already exists${NC}"
else
    cp scripts/templates/vite/.dockerignore "$APP_DIR/.dockerignore"
    echo -e "${GREEN}✅ Created .dockerignore${NC}"
fi

# ============================================
# STEP 5: Add to docker-compose.yml
# ============================================
if [ "$IN_COMPOSE" = false ]; then
    ./scripts/add-to-compose-vite.sh "$APP_NAME"
fi

# ============================================
# STEP 6: Check /etc/hosts
# ============================================
echo ""
echo -e "${BLUE}📋 Final steps:${NC}"

if grep -q "$SAFE_NAME.localhost" /etc/hosts 2>/dev/null; then
    echo -e "${GREEN}✅ $SAFE_NAME.localhost already in /etc/hosts${NC}"
else
    echo -e "${YELLOW}⚠️  Domain not in /etc/hosts yet${NC}"
    echo "   Run: dockerator hosts"
fi


# ============================================
# END SUMMARY AND NEXT STEPS
# ============================================

echo ""
echo -e "${GREEN}🎉 Project '$APP_NAME' ready!${NC}"
echo ""
echo "Next steps:"
echo "  1. Sync hosts: dockerator hosts"
echo "  2. Start container: dockerator start $SAFE_NAME"
echo "  3. Access app: http://$SAFE_NAME.localhost"
echo "  4. View logs: dockerator logs $SAFE_NAME"