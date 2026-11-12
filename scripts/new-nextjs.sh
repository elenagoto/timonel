#!/bin/bash

# Create a new Next.js project
# Usage: ./new-nextjs.sh <project-name>
# With optional database: ./new-nextjs.sh <project-name> <with-db>

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh

APP_NAME=$1
WITH_DB=$2
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

echo -e "${BLUE}Creating Next.js project: $APP_NAME${NC}"
echo ""

# ============================================
# STEP 0: Check if app exists in docker-compose
# ============================================
SAFE_NAME=$(to_safe_name "$APP_NAME")
if project_service_exists "$SAFE_NAME"; then
    echo -e "${YELLOW}⚠️  Project already in docker-compose.yml${NC}"
    IN_COMPOSE=true
else
    IN_COMPOSE=false
fi

# ============================================
# STEP 1: Create folder
# ============================================
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠️  Folder $APP_DIR already exists${NC}"
else
    mkdir -p "$APP_DIR"
    echo -e "${GREEN}✅ Created $APP_DIR${NC}"
fi

# ============================================
# STEP 2: Copy package.json
# ============================================
if [ ! -f "$APP_DIR/package.json" ]; then
    sed -e 's/$APP_NAME/'"$APP_NAME"'/g'  \
        scripts/templates/nextjs/package.json > "$APP_DIR/package.json"
    echo -e "${GREEN}✅ Created package.json${NC}"
else
   echo -e "${YELLOW}⚠️  package.json already exists${NC}"
fi

# ============================================
# STEP 3: Create Dockerfile (shared Node image)
# ============================================
if [ ! -f "$APP_DIR/Dockerfile" ]; then
    cp scripts/templates/stacks/node/Dockerfile "$APP_DIR/"
    echo -e "${GREEN}✅ Created Dockerfile${NC}"
else
    echo -e "${YELLOW}⚠️  Dockerfile already exists${NC}"
fi

# ============================================
# STEP 4: Create .dockerignore
# ============================================
if [ ! -f "$APP_DIR/.dockerignore" ]; then
    cp scripts/templates/stacks/node/.dockerignore "$APP_DIR/"
    echo -e "${GREEN}✅ Created .dockerignore${NC}"
else
    echo -e "${YELLOW}⚠️  .dockerignore already exists${NC}"
fi

# ============================================
# STEP 5: Create minimal Next.js app structure
# ============================================
if [ -d "$APP_DIR/src/app" ]; then
    echo -e "${YELLOW}⚠️  Next.js structure already exists${NC}"
else
    mkdir -p "$APP_DIR/src/app"
    sed -e 's/$APP_NAME/'"$APP_NAME"'/g' \
        -e 's/$SAFE_NAME/'"$SAFE_NAME"'/g' \
        scripts/templates/nextjs/page.tsx > "$APP_DIR/src/app/page.tsx"
    sed -e 's/$APP_NAME/'"$APP_NAME"'/g' \
        -e 's/$SAFE_NAME/'"$SAFE_NAME"'/g' \
        scripts/templates/nextjs/layout.tsx > "$APP_DIR/src/app/layout.tsx"
    cp scripts/templates/nextjs/styles.css "$APP_DIR/src/app/styles.css"
    cp scripts/templates/nextjs/tsconfig.json "$APP_DIR/tsconfig.json"
    cp scripts/templates/nextjs/eslint.config.mjs "$APP_DIR/eslint.config.mjs"
    mkdir -p "$APP_DIR/src/components"
    mkdir -p "$APP_DIR/public"   # Next.js only serves public/ from the project root

    echo -e "${GREEN}✅ Created Next.js structure${NC}"
fi

# ============================================
# STEP 6: Add to docker-compose.yml
# ============================================
if [ "$IN_COMPOSE" = false ]; then
    ./scripts/add-to-compose.sh "$APP_NAME" next "$WITH_DB"
fi

# With --with-db, the container gets DB_* env vars, so the database and user
# they point to must actually exist (same naming as WordPress: underscores)
if [ "$WITH_DB" = "--with-db" ]; then
    SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    echo ""
    ./scripts/create-db.sh "$SAFE_DB"
fi

# ============================================
# STEP 7: Check /etc/hosts
# ============================================
echo ""
echo -e "${BLUE}📋 Final steps:${NC}"

if grep -q "$SAFE_NAME.localhost" /etc/hosts 2>/dev/null; then
    echo -e "${GREEN}✅ $SAFE_NAME.localhost already in /etc/hosts${NC}"
else
    echo -e "${YELLOW}⚠️  Domain not in /etc/hosts yet${NC}"
    echo "   Run: dockerator hosts"
fi

echo ""
echo -e "${GREEN}🎉 Project '$APP_NAME' ready!${NC}"
echo ""
echo "Next steps:"
echo "  1. Sync hosts: dockerator hosts"
echo "  2. Start container: dockerator start $SAFE_NAME"
echo "  3. Access app: http://$SAFE_NAME.localhost"
echo "  4. View logs: dockerator logs $SAFE_NAME"