#!/bin/bash

# Create a new Parcel project
# Usage: ./new-parcel.sh <project-name>

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

echo -e "${BLUE}Creating Parcel project: $APP_NAME${NC}"
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
        scripts/templates/parcel/package.json > "$APP_DIR/package.json"
    echo -e "${GREEN}✅ Created package.json${NC}"
else
   echo -e "${YELLOW}⚠️  package.json already exists${NC}"
fi

# ============================================
# STEP 3: Create Dockerfile
# ============================================
if [ ! -f "$APP_DIR/Dockerfile" ]; then
   cp scripts/templates/parcel/Dockerfile "$APP_DIR/"
    echo -e "${GREEN}✅ Created Dockerfile${NC}"
else
    echo -e "${YELLOW}⚠️  Dockerfile already exists${NC}"
fi

# ============================================
# STEP 4: Create .dockerignore
# ============================================

if [ ! -f "$APP_DIR/.dockerignore" ]; then
    cp scripts/templates/parcel/.dockerignore "$APP_DIR/"
    echo -e "${GREEN}✅ Created .dockerignore${NC}"
else
   echo -e "${YELLOW}⚠️  .dockerignore already exists${NC}"

fi

# ============================================
# STEP 5: Create .parcelrc
# ============================================
if [ ! -f "$APP_DIR/.parcelrc" ]; then
    cp scripts/templates/parcel/.parcelrc "$APP_DIR/"
    echo -e "${GREEN}✅ Created .parcelrc${NC}"
else
    echo -e "${YELLOW}⚠️  .parcelrc already exists${NC}"
fi

# ============================================
# STEP 6: Create minimal Parcel app structure
# ============================================
if [ -f "$APP_DIR/public/index.html" ]; then
    echo -e "${YELLOW}⚠️  Parcel structure already exists${NC}"
else
    # Create directories
    mkdir -p "$APP_DIR/public"
    mkdir -p "$APP_DIR/assets"
    mkdir -p "$APP_DIR/src"
    mkdir -p "$APP_DIR/components/App"

    # Copy public/index.html (with variable substitution)
    sed -e 's/$APP_NAME/'"$APP_NAME"'/g' \
        -e 's/$SAFE_NAME/'"$SAFE_NAME"'/g' \
        scripts/templates/parcel/public/index.html > "$APP_DIR/public/index.html"

    # Copy src files
    cp scripts/templates/parcel/src/index.js "$APP_DIR/src/index.js"
    cp scripts/templates/parcel/src/styles.css "$APP_DIR/src/styles.css"

    # Copy component files (with variable substitution)
    sed -e 's/$APP_NAME/'"$APP_NAME"'/g' \
        -e 's/$SAFE_NAME/'"$SAFE_NAME"'/g' \
        scripts/templates/parcel/components/App/App.js > "$APP_DIR/components/App/App.js"
    cp scripts/templates/parcel/components/App/index.js "$APP_DIR/components/App/index.js"

    # Create empty assets folder with .gitkeep
    touch "$APP_DIR/assets/.gitkeep"

    echo -e "${GREEN}✅ Created Parcel structure${NC}"
fi

# ============================================
# STEP 7: Add to docker-compose.yml
# ============================================
if [ "$IN_COMPOSE" = false ]; then
    ./scripts/add-to-compose-parcel.sh "$APP_NAME"
fi

# ============================================
# STEP 8: Check /etc/hosts
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