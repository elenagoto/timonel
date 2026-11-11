#!/bin/bash

# Remove a service from docker-compose.yml
# Usage: ./remove-from-compose.sh <app-name>

set -e

APP_NAME=$1
COMPOSE_FILE="docker-compose.yml"

if [ -z "$APP_NAME" ]; then
    echo "❌ Error: App name required"
    exit 1
fi

# Sanitize name
SAFE_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

# Check if service exists
if ! grep -q "^  $SAFE_NAME:" "$COMPOSE_FILE"; then
    echo "⚠️  Service '$SAFE_NAME' not found in docker-compose.yml"
    exit 0
fi

# Remove the service block by indentation, not by its last line.
# The block starts at "  <name>:" and owns every following line that is
# blank or indented 3+ spaces. It ends at the first non-blank line indented
# 0-2 spaces (the next service, a "  #" comment, or a top-level key like
# "volumes:"). This works whatever the block's contents are (e.g. a
# restart policy changed to unless-stopped), and can never run on into
# the next service or to the end of the file.
# Blank lines just before the block are dropped too, so separators
# don't pile up; one blank line is kept before whatever follows it.
OUTPUT_FILE=$(mktemp)

awk -v svc="  $SAFE_NAME:" '
{
    line = $0
    sub(/[ \t\r]+$/, "", line)

    if (skip) {
        if (match($0, /[^ \t\r]/) && RSTART <= 3) {
            skip = 0
            buf = "\n"
        } else {
            next
        }
    }

    if (line == "") { buf = buf $0 "\n"; next }

    if (line == svc) { buf = ""; skip = 1; removed = 1; next }

    printf "%s", buf
    buf = ""
    print
}
END {
    printf "%s", buf
    if (!removed) exit 1
}
' "$COMPOSE_FILE" > "$OUTPUT_FILE" || {
    rm -f "$OUTPUT_FILE"
    echo "❌ Error: could not locate the '$SAFE_NAME' block, docker-compose.yml left unchanged"
    exit 1
}

# Sanity check: the top-level structure must survive intact
for key in services volumes networks; do
    if grep -q "^$key:" "$COMPOSE_FILE" && ! grep -q "^$key:" "$OUTPUT_FILE"; then
        rm -f "$OUTPUT_FILE"
        echo "❌ Error: removal would drop '$key:', docker-compose.yml left unchanged"
        exit 1
    fi
done

mv "$OUTPUT_FILE" "$COMPOSE_FILE"

echo "✅ Removed $SAFE_NAME from docker-compose.yml"