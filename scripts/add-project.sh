#!/bin/bash

# Dockerize a project that already exists in apps/<name> (the `add` command)
# Usage: ./add-project.sh <name> [--with-db]
#
# For downloaded projects (course repos, client sites...). Never overwrites
# the project's own files: it only adds what's missing for Docker.
#   1. Detects the framework, then asks you to confirm it (or pick another)
#   2. Adds the stack's Docker files if missing (Dockerfile, .dockerignore,
#      plus Caddyfile for PHP)
#   3. Creates the MySQL database + user (PHP: always; Node: with --with-db)
#   4. Registers the project in docker-compose.yml
# Safe to re-run: on a project that's already registered it skips the
# question and only fills in what's missing.

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

APP_NAME=$1
WITH_DB=$2
APP_DIR="apps/$APP_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$APP_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

if [ -n "$WITH_DB" ] && [ "$WITH_DB" != "--with-db" ]; then
    echo -e "${RED}❌ Error: Unknown option '$WITH_DB' (expected --with-db)${NC}"
    exit 1
fi

if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Error: Folder $APP_DIR doesn't exist${NC}"
    echo "   Put the project in apps/ first, or create a new one with: dockerator new <type> $APP_NAME"
    exit 1
fi

SAFE_NAME=$(to_safe_name "$APP_NAME")
SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

echo -e "${BLUE}Adding existing project: $APP_NAME${NC}"
echo ""

# ============================================
# STEP 1: Framework (detected, then confirmed)
# ============================================
if project_service_exists "$SAFE_NAME"; then
    ALREADY_REGISTERED=true
    FRAMEWORK=$(project_framework "$APP_NAME" || true)
    echo -e "${YELLOW}⚠️  Already in docker-compose.yml${NC} - only filling in what's missing"
fi

if [ -z "$FRAMEWORK" ]; then
    ALREADY_REGISTERED=${ALREADY_REGISTERED:-false}
    DETECTED=$(detect_framework "$APP_DIR" || true)

    echo "Which framework does '$APP_NAME' use?"
    i=0
    DEFAULT_CHOICE=""
    for fw in $KNOWN_FRAMEWORKS; do
        i=$((i + 1))
        if [ "$fw" = "$DETECTED" ]; then
            echo -e "  $i) $(framework_setting "$fw" display)  ${GREEN}← detected${NC}"
            DEFAULT_CHOICE=$i
        else
            echo "  $i) $(framework_setting "$fw" display)"
        fi
    done

    while [ -z "$FRAMEWORK" ]; do
        if [ -n "$DEFAULT_CHOICE" ]; then
            PROMPT="Choose 1-$i [Enter = $DEFAULT_CHOICE]: "
        else
            PROMPT="Couldn't detect it. Choose 1-$i: "
        fi
        if ! read -r -p "$PROMPT" ANSWER; then
            # No input available (e.g. not a terminal): take the detected one
            ANSWER=""
            [ -z "$DEFAULT_CHOICE" ] && { echo ""; echo -e "${RED}❌ No framework chosen${NC}"; exit 1; }
        fi
        ANSWER=${ANSWER:-$DEFAULT_CHOICE}

        # Accept a number from the list or a framework name
        j=0
        for fw in $KNOWN_FRAMEWORKS; do
            j=$((j + 1))
            if [ "$ANSWER" = "$j" ] || [ "$ANSWER" = "$fw" ]; then
                FRAMEWORK=$fw
            fi
        done
        [ -z "$FRAMEWORK" ] && echo -e "${YELLOW}   Please enter a number from the list${NC}"
    done
    echo -e "${GREEN}✅ Framework: $(framework_setting "$FRAMEWORK" display)${NC}"
fi

STACK=$(framework_setting "$FRAMEWORK" stack)

# ============================================
# STEP 2: Docker files for the stack (only if missing)
# ============================================
case "$STACK" in
    node) STACK_FILES="Dockerfile .dockerignore" ;;
    php)  STACK_FILES="Dockerfile .dockerignore Caddyfile" ;;
esac
for file in $STACK_FILES; do
    if [ -f "$APP_DIR/$file" ]; then
        echo -e "${YELLOW}⚠️  $file already exists, kept as is${NC}"
    else
        cp "scripts/templates/stacks/$STACK/$file" "$APP_DIR/$file"
        echo -e "${GREEN}✅ Created $file${NC}"
    fi
done

# ============================================
# STEP 3: Framework extras (additive only, never overwriting)
# ============================================
if [ "$FRAMEWORK" = "wordpress" ]; then
    # Route WordPress mail to Mailpit
    MU_PLUGIN="$APP_DIR/wp-content/mu-plugins/dockerator-mailpit.php"
    if [ -d "$APP_DIR/wp-content" ] && [ ! -f "$MU_PLUGIN" ]; then
        mkdir -p "$APP_DIR/wp-content/mu-plugins"
        cp scripts/templates/wordpress/dockerator-mailpit.php "$MU_PLUGIN"
        echo -e "${GREEN}✅ Created Mailpit mu-plugin${NC}"
    fi

    # Database settings: point them out, but don't edit the project's config
    if [ ! -f "$APP_DIR/wp-config.php" ]; then
        echo -e "${YELLOW}⚠️  No wp-config.php. Create one (wp-config-sample.php is a starting point) with:${NC}"
        WP_DB_HINT=true
    elif ! grep -qE "DB_HOST'[[:space:]]*,[[:space:]]*'mysql'" "$APP_DIR/wp-config.php"; then
        echo -e "${YELLOW}⚠️  wp-config.php doesn't use the shared MySQL server. Set:${NC}"
        WP_DB_HINT=true
    fi
    if [ "$WP_DB_HINT" = true ]; then
        echo "   DB_NAME '$SAFE_DB', DB_USER '$SAFE_DB', DB_PASSWORD '$SAFE_DB', DB_HOST 'mysql'"
    fi
fi

# ============================================
# STEP 4: Database (PHP: always; Node: with --with-db)
# ============================================
if [ "$STACK" = "php" ] || [ "$WITH_DB" = "--with-db" ]; then
    echo ""
    ./scripts/create-db.sh "$SAFE_DB"
fi

# ============================================
# STEP 5: Register in docker-compose.yml
# ============================================
echo ""
if [ "$ALREADY_REGISTERED" = true ]; then
    echo -e "${YELLOW}⚠️  Already in docker-compose.yml, not changed${NC}"
else
    ./scripts/add-to-compose.sh "$APP_NAME" "$FRAMEWORK" "$WITH_DB"
fi

echo ""
echo -e "${GREEN}🎉 Project '$APP_NAME' is ready to run in Docker${NC}"
echo ""
echo "Next steps:"
echo "  1. Start container: dockerator start $SAFE_NAME"
echo "  2. Access app: http://$SAFE_NAME.localhost"
echo "  3. Dev shell: dockerator dev $SAFE_NAME"
