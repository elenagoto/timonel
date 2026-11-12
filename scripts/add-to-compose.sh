#!/bin/bash

# Add a Node project service to docker-compose.yml
# Usage: ./add-to-compose.sh <app-name> <framework> [--with-db]
#   framework: next | vite | parcel (see scripts/lib/frameworks.sh)
#
# Port, cache volumes and dev-server flags come from the framework settings,
# so every Node framework gets the same block shape. The block is labelled
# with its stack and framework so other commands don't have to guess.
# (WordPress still uses add-to-compose-wp.sh.)

set -e

source scripts/lib/project.sh
source scripts/lib/compose.sh
source scripts/lib/frameworks.sh

APP_NAME=$1
FRAMEWORK=$2
WITH_DB=$3
COMPOSE_FILE="docker-compose.yml"

if [ -z "$APP_NAME" ] || [ -z "$FRAMEWORK" ]; then
    echo "❌ Usage: add-to-compose.sh <app-name> <framework> [--with-db]"
    exit 1
fi

if ! is_known_framework "$FRAMEWORK"; then
    echo "❌ Error: Unknown framework '$FRAMEWORK' (known: $KNOWN_FRAMEWORKS)"
    exit 1
fi

STACK=$(framework_setting "$FRAMEWORK" stack)
if [ "$STACK" != "node" ]; then
    echo "❌ Error: '$FRAMEWORK' is a $STACK project; only the node stack is handled here"
    exit 1
fi

if [ -n "$WITH_DB" ] && [ "$WITH_DB" != "--with-db" ]; then
    echo "❌ Error: Unknown option '$WITH_DB' (expected --with-db)"
    exit 1
fi

SAFE_NAME=$(to_safe_name "$APP_NAME")
SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

if project_service_exists "$SAFE_NAME" "$COMPOSE_FILE"; then
    echo "⚠️  Service '$SAFE_NAME' already exists in docker-compose.yml"
    echo "   Skipping docker-compose.yml update"
    exit 0
fi

PORT=$(framework_setting "$FRAMEWORK" port)
CACHE_VOLUMES=$(framework_setting "$FRAMEWORK" cache_volumes)
DEV_ARGS=$(framework_setting "$FRAMEWORK" dev_args)

# Build the service block line by line (echo, not a heredoc, so nothing in
# it is ever run as a command substitution)
SERVICE_FILE=$(mktemp)
{
    echo ""
    echo "  $SAFE_NAME:"
    echo "    build:"
    echo "      context: ./apps/$APP_NAME"
    echo "      dockerfile: Dockerfile"
    echo "    container_name: dockerator_$SAFE_NAME"
    echo "    profiles:"
    echo "      - projects"
    echo "    labels:"
    echo "      - \"traefik.enable=true\""
    echo "      - \"traefik.http.routers.$SAFE_NAME.rule=Host(\`$SAFE_NAME.localhost\`)\""
    echo "      - \"traefik.http.services.$SAFE_NAME.loadbalancer.server.port=$PORT\""
    echo "      - \"dockerator.stack=$STACK\""
    echo "      - \"dockerator.framework=$FRAMEWORK\""

    if [ -n "$DEV_ARGS" ]; then
        # e.g. command: ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
        CMD='["npm", "run", "dev", "--"'
        for arg in $DEV_ARGS; do CMD="$CMD, \"$arg\""; done
        echo "    command: $CMD]"
    fi

    echo "    volumes:"
    echo "      - ./apps/$APP_NAME:/app"
    for path in $CACHE_VOLUMES; do
        echo "      - $path"
    done

    if [ "$WITH_DB" = "--with-db" ]; then
        echo "    environment:"
        echo "      - DB_NAME=$SAFE_DB"
        echo "      - DB_USER=$SAFE_DB"
        echo "      - DB_PASSWORD=$SAFE_DB"
        echo "      - DB_HOST=mysql"
    fi

    echo "    networks:"
    echo "      - dockerator"

    if [ "$WITH_DB" = "--with-db" ]; then
        echo "    depends_on:"
        echo "      mysql:"
        echo "        condition: service_healthy"
    fi

    echo "    restart: \"no\"  # change to unless-stopped if you want it to persist"
} > "$SERVICE_FILE"

# Insert the service block before the volumes:/networks: keys
insert_service_block "$SERVICE_FILE" "$COMPOSE_FILE"
rm "$SERVICE_FILE"

echo "✅ Added $SAFE_NAME to docker-compose.yml ($(framework_setting "$FRAMEWORK" display), port $PORT)"
