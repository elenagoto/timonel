#!/bin/bash

# Install Timonel: run this once after cloning (from any folder):
#   bash /path/to/timonel/install.sh
#
# What it does (safe to run again):
#   1. Makes the scripts executable and creates docker-compose.yml
#   2. Removes leftovers of the old `dockerator` install
#   3. Links the `timonel` command into /usr/local/bin (sudo only if needed)
#   4. Sets up tab completion for your login shell (zsh or bash)
#
# For testing, the link folder can be overridden: TIMONEL_BIN_DIR=/tmp/bin

set -e

# The repo folder is wherever this script lives (works from any directory,
# and with spaces in the path)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${TIMONEL_BIN_DIR:-/usr/local/bin}"
LOGIN_SHELL="$(basename "${SHELL:-}")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Run a command, with sudo only if the target folder isn't writable
as_needed() {
    local dir="$1"; shift
    if [ -w "$dir" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

echo -e "${BLUE}🔧 Setting up Timonel in $REPO_DIR${NC}"
echo ""

# ============================================
# STEP 1: Scripts and docker-compose.yml
# ============================================
chmod +x "$REPO_DIR/timonel" "$REPO_DIR"/scripts/*.sh
echo -e "${GREEN}✅ Scripts are executable${NC}"

if [ ! -f "$REPO_DIR/docker-compose.yml" ]; then
    cp "$REPO_DIR/docker-compose.yml.example" "$REPO_DIR/docker-compose.yml"
    echo -e "${GREEN}✅ Created docker-compose.yml${NC}"
else
    echo -e "${YELLOW}⚠️  docker-compose.yml already exists, kept as is${NC}"
fi

# ============================================
# STEP 2: Leftovers of the old `dockerator` install
# ============================================
# Only links pointing into a Dockerator/Timonel checkout are removed, so
# nothing unrelated with the same name is touched.
remove_old_link() {
    local link="$1" target
    [ -L "$link" ] || return 0
    target="$(readlink "$link")"
    case "$target" in
        *dockerator*|*timonel*)
            as_needed "$(dirname "$link")" rm "$link"
            echo -e "${GREEN}✅ Removed old $link${NC}"
            ;;
    esac
}
remove_old_link "$BIN_DIR/dockerator"
remove_old_link "$HOME/.zsh/completion/_dockerator"
remove_old_link "/etc/bash_completion.d/dockerator"
remove_old_link "$HOME/.bash_completion.d/dockerator"
if [ -f "$HOME/.dockerator-path" ]; then
    rm "$HOME/.dockerator-path"
    echo -e "${GREEN}✅ Removed old ~/.dockerator-path${NC}"
fi

# ============================================
# STEP 3: The `timonel` command
# ============================================
if [ ! -d "$BIN_DIR" ]; then
    as_needed "$(dirname "$BIN_DIR")" mkdir -p "$BIN_DIR"
fi
if [ -e "$BIN_DIR/timonel" ] && [ ! -L "$BIN_DIR/timonel" ]; then
    echo -e "${RED}❌ $BIN_DIR/timonel exists and isn't a link; leaving it alone${NC}"
    echo "   Remove it yourself, then run this script again."
    exit 1
elif [ "$(readlink "$BIN_DIR/timonel" 2>/dev/null)" = "$REPO_DIR/timonel" ]; then
    echo -e "${YELLOW}⚠️  $BIN_DIR/timonel already points here${NC}"
else
    # -f replaces a link to an older checkout
    as_needed "$BIN_DIR" ln -sf "$REPO_DIR/timonel" "$BIN_DIR/timonel"
    echo -e "${GREEN}✅ Linked $BIN_DIR/timonel -> $REPO_DIR/timonel${NC}"
fi

# ============================================
# STEP 4: Tab completion
# ============================================
# Completion finds your projects through this file
echo "$REPO_DIR" > "$HOME/.timonel-path"

# Add a marked block to a shell config file, once
add_rc_block() {
    local rc="$1" block="$2"
    if [ -f "$rc" ] && grep -q "# >>> timonel completion >>>" "$rc"; then
        echo -e "${YELLOW}⚠️  Completion already set up in $rc${NC}"
        return 0
    fi
    {
        echo ""
        echo "# >>> timonel completion >>>"
        echo "$block"
        echo "# <<< timonel completion <<<"
    } >> "$rc"
    echo -e "${GREEN}✅ Added completion setup to $rc${NC}"
}

case "$LOGIN_SHELL" in
    zsh)
        mkdir -p "$HOME/.zsh/completion"
        ln -sf "$REPO_DIR/timonel-completion.zsh" "$HOME/.zsh/completion/_timonel"
        echo -e "${GREEN}✅ Linked ~/.zsh/completion/_timonel${NC}"
        # zsh only finds completions in folders listed in fpath, and only
        # after compinit runs (running it again is harmless)
        add_rc_block "$HOME/.zshrc" 'fpath=("$HOME/.zsh/completion" $fpath)
autoload -Uz compinit && compinit'
        ;;
    bash)
        add_rc_block "$HOME/.bashrc" "source \"$REPO_DIR/timonel-completion.bash\""
        ;;
    *)
        echo -e "${YELLOW}⚠️  Shell '$LOGIN_SHELL' not recognised: no tab completion set up${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Timonel is installed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal window (for the command and tab completion)"
echo "  2. timonel up                      # start the shared services"
echo "  3. timonel new nextjs my-app       # or: vite, parcel, wp, laravel"
echo "     timonel add my-downloaded-app   # for a project already in apps/"
echo ""
echo "Tip: if Safari or a command-line tool can't open http://<name>.localhost,"
echo "run 'timonel hosts' once (Chrome and Firefox don't need it)."
