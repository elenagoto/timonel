#!/bin/bash
# Run this after cloning: ./install.sh

echo "🔧 Setting up Timonel..."

# Make all scripts executable
chmod +x timonel
chmod +x scripts/*.sh

# Copy example compose file
if [ ! -f docker-compose.yml ]; then
    cp docker-compose.yml.example docker-compose.yml
    echo "✅ Created docker-compose.yml"
fi

# Create symlink
if [ ! -L /usr/local/bin/timonel ]; then
    sudo ln -s $(pwd)/timonel /usr/local/bin/timonel
    echo "✅ Created global command"
fi

echo "🔧 Setting up autocomplete..."

# Save timonel path for completion
echo "$(pwd)" > ~/.timonel-path

# Detect shell
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    # Zsh
    mkdir -p ~/.zsh/completion
    ln -sf "$(pwd)/timonel-completion.zsh" ~/.zsh/completion/_timonel
    echo "✅ Zsh completion installed (restart terminal to activate)"
elif [ -n "$BASH_VERSION" ]; then
    # Bash
    sudo ln -sf "$(pwd)/timonel-completion.bash" /etc/bash_completion.d/timonel 2>/dev/null || \
        ln -sf "$(pwd)/timonel-completion.bash" ~/.bash_completion.d/timonel
    echo "✅ Bash completion installed (restart terminal to activate)"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal window"
echo "  2. timonel up"
echo "  3. timonel hosts"
echo "  4. timonel new nextjs <project-name>  | timonel new wp <project-name> | timonel new vite <project-name> | timonel new parcel <project-name>" 
echo ""