#!/bin/bash

# Show recent commands from the command log (the `history` command)
# Usage: ./show-history.sh            last 20 runs, one line each
#        ./show-history.sh --errors   last 5 failed runs, with their output
#
# The log (logs/timonel.log) is written by the `timonel` dispatcher:
#   === <date> <time>  timonel <args>
#   <output lines>
#   --- exit <code> in <seconds>s   |   --- interrupted (exit <code>) after <s>s

set -e

LOG_FILE="logs/timonel.log"
MODE=${1-}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$MODE" in
    ""|--errors) ;;
    *)
        echo -e "${RED}❌ Unknown option: $MODE${NC}"
        echo "   Usage: timonel history [--errors]"
        exit 1
        ;;
esac

if [ ! -s "$LOG_FILE" ]; then
    echo "No commands recorded yet."
    echo "Every timonel command is logged in $LOG_FILE from now on."
    exit 0
fi

if [ -z "$MODE" ]; then
    echo -e "${BLUE}📜 Recent commands${NC} (newest last)"
    echo ""
    # One line per run. Runs without an end line are still going (or were
    # cut off); lines before the first header (after trimming) are skipped.
    awk -v green="$GREEN" -v red="$RED" -v yellow="$YELLOW" -v nc="$NC" '
        function flush() {
            if (!have) return
            if (status == "")              { mark = yellow "…" nc; note = "(running or unfinished)" }
            else if (status == "0")        { mark = green "✓" nc;  note = "(" secs ")" }
            else if (status == "int")      { mark = yellow "⏹" nc; note = "interrupted after " secs }
            else                           { mark = red "✗" nc;    note = "exit " status " after " secs }
            line[++n] = sprintf("  %s %s  %-44s %s", mark, when, cmd, note)
            have = 0
        }
        /^=== / {
            flush()
            when = $2 " " $3
            cmd = $0; sub(/^=== [^ ]+ [^ ]+  /, "", cmd)
            status = ""; secs = ""; have = 1
            next
        }
        have && /^--- exit / { status = $3; secs = $5; next }
        have && /^--- interrupted / { status = "int"; secs = $NF; next }
        END {
            flush()
            start = n > 20 ? n - 19 : 1
            for (i = start; i <= n; i++) print line[i]
        }
    ' "$LOG_FILE" | while IFS= read -r l; do echo -e "$l"; done
    echo ""
    echo "Failed runs with their output: timonel history --errors"
    echo "Full log: $PWD/$LOG_FILE"
    exit 0
fi

# --errors: the last 5 failed runs, with the output they printed
echo -e "${BLUE}📜 Recent failed commands${NC} (newest last)"
FOUND=$(awk '
    function flush() {
        if (have && failed) { block[++n] = header "\n" body footer }
        have = 0
    }
    /^=== / { flush(); header = $0; body = ""; footer = ""; failed = 0; have = 1; next }
    have && /^--- exit / { footer = $0; failed = ($3 != "0"); next }
    have && /^--- interrupted / { footer = $0; failed = 1; next }
    have { body = body $0 "\n" }
    END {
        flush()
        start = n > 5 ? n - 4 : 1
        for (i = start; i <= n; i++) printf "%s\n\n", block[i]
    }
' "$LOG_FILE")

if [ -z "$FOUND" ]; then
    echo ""
    echo -e "${GREEN}✅ No failed commands in the log${NC}"
else
    echo ""
    echo "$FOUND"
fi
echo "Full log: $PWD/$LOG_FILE"
