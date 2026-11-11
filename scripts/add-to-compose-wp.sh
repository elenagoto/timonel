#!/bin/bash

# Add a WordPress service to docker-compose.yml
# Usage: ./add-to-compose-wp.sh <app-name>

APP_NAME=$1
COMPOSE_FILE="docker-compose.yml"

source scripts/lib/compose.sh

if [ -z "$APP_NAME" ]; then
    echo "❌ Error: App name required"
    exit 1
fi

# Sanitize name for URL (dashes)
SAFE_URL=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

# Sanitize name for database (underscores)
SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

# CHECK: Does service already exist?
if grep -q "^  $SAFE_URL:" "$COMPOSE_FILE"; then
    echo "⚠️  Service '$SAFE_URL' already exists in docker-compose.yml"
    exit 0
fi

# Create temporary file for the service block
SERVICE_FILE=$(mktemp)
cat > "$SERVICE_FILE" << EOF

  $SAFE_URL:
    build:
      context: ./apps/$APP_NAME
      dockerfile: Dockerfile
    container_name: dockerator_$SAFE_URL
    profiles:
      - projects
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.$SAFE_URL.rule=Host(\`$SAFE_URL.localhost\`)"
      - "traefik.http.services.$SAFE_URL.loadbalancer.server.port=80"
    # No fixed ports: dockerator dev-wp publishes 5173 (Vite HMR) only while
    # dev mode is open, so several WordPress projects can run side by side
    volumes:
      - ./apps/$APP_NAME:/app
      - ./apps/$APP_NAME/Caddyfile:/etc/caddy/Caddyfile
    environment:
      - DB_NAME=$SAFE_DB
      - DB_USER=$SAFE_DB
      - DB_PASSWORD=$SAFE_DB
      - DB_HOST=mysql
    networks:
      - dockerator
    depends_on:
      mysql:
        condition: service_healthy
    restart: "no"  # change to unless-stopped if you want it to persist
EOF

# Insert the service block before the volumes:/networks: keys
insert_service_block "$SERVICE_FILE" "$COMPOSE_FILE"
rm "$SERVICE_FILE"

echo "✅ Added $SAFE_URL to docker-compose.yml"