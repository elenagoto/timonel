#!/bin/bash

# Sync /etc/hosts with domains from docker-compose.yml
# Usage: ./sync-hosts.sh

set -e

# Check if running with sudo, if not, re-run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "🔐 This command requires sudo access to modify /etc/hosts"
    exec sudo "$0" "$@"
fi

COMPOSE_FILE="docker-compose.yml"
HOSTS_FILE="/etc/hosts"
MARKER_START="# Timonel managed hosts - DO NOT EDIT MANUALLY"
MARKER_END="# End Timonel managed hosts"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Scanning docker-compose.yml for domains...${NC}"


# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Error: docker-compose.yml not found${NC}"
    exit 1
fi

# Extract all *.localhost domains from Traefik labels
DOMAINS=$(grep -v "^[[:space:]]*#" "$COMPOSE_FILE" | \
    grep -oE "Host\(\`[^)]+\.localhost\`\)" | \
    sed -E "s/Host\(\`(.+\.localhost)\`\)/\1/" | \
    sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${YELLOW}⚠️  No *.localhost domains found${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Found domains:${NC}"
echo "$DOMAINS" | while read domain; do
    echo "   • $domain"
done

echo ""
echo -e "${BLUE}📝 Updating /etc/hosts...${NC}"

# Create temporary file with new hosts entries
TEMP_HOSTS=$(mktemp)

# Build the new hosts block
{
    echo "$MARKER_START"
    echo "# IPv4"
    echo -n "127.0.0.1 "
    echo "$DOMAINS" | tr '\n' ' '
    echo ""
    echo "# IPv6"
    echo -n "::1 "
    echo "$DOMAINS" | tr '\n' ' '
    echo ""
    echo "$MARKER_END"
} > "$TEMP_HOSTS"

# Check if markers already exist in /etc/hosts
if grep -q "$MARKER_START" "$HOSTS_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Timonel entries already exist, replacing...${NC}"
    
    # Remove old Timonel block and add new one
    sudo sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
fi

# Append new hosts block
sudo sh -c "cat $TEMP_HOSTS >> $HOSTS_FILE"

# Cleanup
rm "$TEMP_HOSTS"

echo -e "${GREEN}✅ /etc/hosts updated successfully!${NC}"
echo ""
echo -e "${BLUE}Current Timonel domains in /etc/hosts:${NC}"
sudo sed -n "/$MARKER_START/,/$MARKER_END/p" "$HOSTS_FILE"