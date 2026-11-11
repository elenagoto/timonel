#!/bin/bash

# Create a MySQL database and a user with the same name and password
# in the shared dockerator_mysql container.
# Usage: ./create-db.sh <db-name>
#
# Starts MySQL (and waits until it is healthy) if it isn't running yet.
# Safe to re-run: every statement is IF NOT EXISTS / idempotent.

set -e

DB_NAME=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$DB_NAME" ]; then
    echo -e "${RED}❌ Error: Database name required${NC}"
    exit 1
fi

# The name goes into SQL unquoted-safe positions, so keep it strict
if [[ ! "$DB_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid database name '$DB_NAME' (use a-z, 0-9, _)${NC}"
    exit 1
fi

echo -e "${BLUE}🗄️  Setting up database '$DB_NAME'...${NC}"

# Start MySQL if needed and wait for its healthcheck (no-op if already healthy)
echo -e "${BLUE}   Waiting for MySQL to be ready...${NC}"
docker-compose up -d --wait mysql

docker exec -e MYSQL_PWD=dockerator dockerator_mysql mysql -uroot -e "
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '$DB_NAME'@'%' IDENTIFIED BY '$DB_NAME';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_NAME'@'%';
    FLUSH PRIVILEGES;
"

echo -e "${GREEN}✅ Database ready: $DB_NAME (user: $DB_NAME / password: $DB_NAME)${NC}"
