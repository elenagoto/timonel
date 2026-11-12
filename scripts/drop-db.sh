#!/bin/bash

# Delete a project's MySQL database and its user (same name) from the
# shared timonel_mysql container. Counterpart of create-db.sh.
# Usage: ./drop-db.sh <db-name>
#
# Starts MySQL (and waits until it is healthy) if it isn't running yet.
# Safe to re-run: DROP ... IF EXISTS.

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

# The name goes into SQL, so keep it strict (same rule as create-db.sh)
if [[ ! "$DB_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid database name '$DB_NAME' (use a-z, 0-9, _)${NC}"
    exit 1
fi

echo -e "${BLUE}🗄️  Deleting database '$DB_NAME' and its user...${NC}"

# Start MySQL if needed and wait for its healthcheck (no-op if already healthy)
docker-compose up -d --wait mysql

docker exec -e MYSQL_PWD=timonel timonel_mysql mysql -uroot -e "
    DROP DATABASE IF EXISTS \`$DB_NAME\`;
    DROP USER IF EXISTS '$DB_NAME'@'%';
    FLUSH PRIVILEGES;
"

echo -e "${GREEN}✅ Database and user '$DB_NAME' deleted${NC}"
