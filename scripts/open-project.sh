#!/bin/bash

# Open a project in VS Code
# Usage: ./open-project.sh <project-name>

set -e

PROJECT_NAME=$1
SAFE_URL=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

# Get the directory where dockerator is installed (resolve symlink)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERATOR_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

APP_DIR="$DOCKERATOR_DIR/apps/$PROJECT_NAME"

# Check if project exists
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found${NC}"
    echo "   Looking for: $APP_DIR"
    exit 1
fi

# Determine if it's WordPress or Next.js
THEME_DIR="$APP_DIR/wp-content/themes/$PROJECT_NAME"

if [ -d "$THEME_DIR" ]; then
    # WordPress project - open theme directory
    echo -e "${BLUE}📂 Opening WordPress theme: $PROJECT_NAME${NC}"
    code "$THEME_DIR"
else
    # Other type of project - open project root
    echo -e "${BLUE}📂 Opening project: $PROJECT_NAME${NC}"
    code "$APP_DIR"
fi

echo -e "${GREEN}✅ Opened in VS Code${NC}"