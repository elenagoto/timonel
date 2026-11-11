#!/bin/bash

# Add a new service to docker-compose.yml with safety checks
# Usage: ./add-to-compose-nextjs.sh <app-name>

APP_NAME=$1
WITH_DB=$2

COMPOSE_FILE="docker-compose.yml"

source scripts/lib/compose.sh

if [ -z "$APP_NAME" ]; then
    echo "❌ Error: App name required"
    exit 1
fi

# Sanitize name
SAFE_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
# Sanitize name for database (underscores)
SAFE_DB=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

# CHECK: Does service already exist in docker-compose.yml?
if grep -q "^  $SAFE_NAME:" "$COMPOSE_FILE"; then
    echo "⚠️  Service '$SAFE_NAME' already exists in docker-compose.yml"
    echo "   Skipping docker-compose.yml update"
    exit 0
fi

# Create temporary file for the service block
SERVICE_FILE=$(mktemp)
cat > "$SERVICE_FILE" << EOF

  $SAFE_NAME:
    build:
      context: ./apps/$APP_NAME
      dockerfile: Dockerfile
    container_name: dockerator_$SAFE_NAME
    profiles:
      - projects
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.$SAFE_NAME.rule=Host(\`$SAFE_NAME.localhost\`)"
      - "traefik.http.services.$SAFE_NAME.loadbalancer.server.port=3000"
    volumes:
      - ./apps/$APP_NAME:/app
      - /app/node_modules
      - /app/.next
EOF

if [ "$WITH_DB" = "--with-db" ]; then
    cat >> "$SERVICE_FILE" << EOF
    environment:
      - DB_NAME=$SAFE_DB
      - DB_USER=$SAFE_DB
      - DB_PASSWORD=$SAFE_DB
      - DB_HOST=mysql
EOF
fi

cat >> "$SERVICE_FILE" << EOF
    networks:
      - dockerator
EOF

if [ "$WITH_DB" = "--with-db" ]; then
    cat >> "$SERVICE_FILE" << EOF
    depends_on:
      mysql:
        condition: service_healthy
EOF
fi

cat >> "$SERVICE_FILE" << EOF
    restart: "no"  # change to unless-stopped if you want it to persist
    
EOF

# Insert the service block before the volumes:/networks: keys
insert_service_block "$SERVICE_FILE" "$COMPOSE_FILE"
rm "$SERVICE_FILE"

echo "✅ Added $SAFE_NAME to docker-compose.yml"