#!/bin/bash

# Create a new WordPress project
# Usage: ./new-wordpress.sh <project-name>

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh

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

# Sanitize names
SAFE_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')  # For database: hello_friend
SAFE_URL=$(to_safe_name "$APP_NAME")   # For URL: hello-friend

echo -e "${BLUE}Creating WordPress project: $APP_NAME${NC}"
echo ""

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
# STEP 2: Download WordPress
# ============================================
JUST_DOWNLOADED=false
if [ -f "$APP_DIR/wp-config.php" ]; then
    echo -e "${YELLOW}⚠️  WordPress already exists${NC}"
else
    echo -e "${BLUE}📥 Downloading WordPress...${NC}"
    curl -sS https://wordpress.org/latest.tar.gz | tar -xz -C "$APP_DIR" --strip-components=1
    JUST_DOWNLOADED=true
    echo -e "${GREEN}✅ WordPress downloaded${NC}"
fi
THEMES_DIR="$APP_DIR/wp-content/themes"
THEME_DIR="$THEMES_DIR/$APP_NAME"

# Remove default WordPress themes - only right after a fresh download,
# so re-running this script never deletes the project's own theme
if [ "$JUST_DOWNLOADED" = true ] && [ -d "$THEMES_DIR" ]; then
    echo -e "${BLUE}🧹 Cleaning default themes...${NC}"
    rm -rf "$THEMES_DIR"/*
    echo -e "${GREEN}✅ Removed default themes${NC}"
fi

# Create project theme directory
if [ ! -d "$THEME_DIR" ]; then
    mkdir -p "$THEME_DIR"
    echo -e "${GREEN}✅ Created theme directory: $APP_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  Theme directory already exists${NC}"
fi
# ============================================
# STEP 3: Copy Dockerfile, .dockerignore and Caddyfile (shared PHP stack)
# ============================================
for file in Dockerfile .dockerignore Caddyfile; do
    if [ ! -f "$APP_DIR/$file" ]; then
        cp "scripts/templates/stacks/php/$file" "$APP_DIR/"
        echo -e "${GREEN}✅ Created $file${NC}"
    else
        echo -e "${YELLOW}⚠️  $file already exists${NC}"
    fi
done

# Route WordPress mail to Mailpit (WordPress ignores SMTP_* constants alone)
MU_PLUGIN="$APP_DIR/wp-content/mu-plugins/timonel-mailpit.php"
if [ ! -f "$MU_PLUGIN" ]; then
    mkdir -p "$APP_DIR/wp-content/mu-plugins"
    cp scripts/templates/wordpress/timonel-mailpit.php "$MU_PLUGIN"
    echo -e "${GREEN}✅ Created Mailpit mu-plugin${NC}"
else
    echo -e "${YELLOW}⚠️  Mailpit mu-plugin already exists${NC}"
fi

# ============================================
# STEP 4: Generate wp-config.php
# ============================================
if [ ! -f "$APP_DIR/wp-config.php" ]; then
    echo -e "${BLUE}🔧 Generating wp-config.php...${NC}"
    
    # Get WordPress salt keys
    SALT_KEYS=$(curl -sS https://api.wordpress.org/secret-key/1.1/salt/)
    
    # Create wp-config from template
    sed -e "s/{{DB_NAME}}/$SAFE_NAME/g" \
        -e "s/{{DB_USER}}/$SAFE_NAME/g" \
        -e "s/{{DB_PASSWORD}}/$SAFE_NAME/g" \
        -e "/{{SALT_KEYS}}/r /dev/stdin" \
        -e "/{{SALT_KEYS}}/d" \
        scripts/templates/wordpress/wp-config.php.template <<< "$SALT_KEYS" > "$APP_DIR/wp-config.php"
    
    echo -e "${GREEN}✅ Created wp-config.php${NC}"
else
    echo -e "${YELLOW}⚠️  wp-config.php already exists${NC}"
fi
# ============================================
# STEP 5: Create MySQL database and user
# ============================================
echo ""
# Starts MySQL if needed, waits until healthy, then creates db + user (idempotent)
./scripts/create-db.sh "$SAFE_NAME"
# ============================================
# STEP 6: Add to docker-compose.yml
# ============================================
echo ""
if project_service_exists "$SAFE_URL"; then
    echo -e "${YELLOW}⚠️  Already in docker-compose.yml${NC}"
else
    # Create service block for WordPress (php stack, always with a database)
    ./scripts/add-to-compose.sh "$APP_NAME" wordpress
fi

# ============================================
# STEP 7: Remind about /etc/hosts
# ============================================
echo ""
echo -e "${BLUE}📋 Final steps:${NC}"

if grep -q "$SAFE_URL.localhost" /etc/hosts 2>/dev/null; then
    echo -e "${GREEN}✅ $SAFE_URL.localhost already in /etc/hosts${NC}"
else
    echo -e "${YELLOW}⚠️  Domain not in /etc/hosts yet${NC}"
    echo "   Run: timonel hosts"
fi

echo ""
echo -e "${GREEN}🎉 WordPress project '$APP_NAME' ready!${NC}"
echo ""
echo "Database credentials:"
echo "  Database: $SAFE_NAME"
echo "  User: $SAFE_NAME"
echo "  Password: $SAFE_NAME"
echo ""
echo "Next steps:"
echo "  1. Sync hosts: timonel hosts"
echo "  2. Start container: timonel start $SAFE_URL"
echo "  3. Visit: http://$SAFE_URL.localhost"
echo "  4. Complete WordPress installation"
echo ""
