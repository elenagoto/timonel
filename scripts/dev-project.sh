#!/bin/bash

# Enter development mode for any project (the `dev` command)
# Usage: ./dev-project.sh <project-name>
#
# Finds the project's framework (compose label, else its files) and hands
# over to the stack's dev mode:
#   node (Next.js, Vite, Parcel) -> dev-mode-node.sh: shell in /app
#   php  (WordPress, Laravel)    -> dev-mode-php.sh:  publishes Vite's port
#                                   5173 while the shell is open

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

PROJECT_NAME=$1

# Colors
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: Project name required${NC}"
    exit 1
fi

SAFE_NAME=$(to_safe_name "$PROJECT_NAME")
if ! project_service_exists "$SAFE_NAME"; then
    echo -e "${RED}❌ Error: Project '$PROJECT_NAME' not found in docker-compose.yml${NC}"
    exit 1
fi

FRAMEWORK=$(project_framework "$PROJECT_NAME" || true)
if [ -z "$FRAMEWORK" ]; then
    echo -e "${RED}❌ Error: Can't tell which framework '$PROJECT_NAME' uses${NC}"
    echo "   Known: $KNOWN_FRAMEWORKS"
    exit 1
fi

case "$(framework_setting "$FRAMEWORK" stack)" in
    node) exec ./scripts/dev-mode-node.sh "$PROJECT_NAME" "$FRAMEWORK" ;;
    php)  exec ./scripts/dev-mode-php.sh "$PROJECT_NAME" "$FRAMEWORK" ;;
esac
