#!/bin/bash
# Bash completion for timonel
# Install: sudo cp timonel-completion.bash /etc/bash_completion.d/timonel

_timonel_completions() {
    local cur prev commands projects
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    commands="new add open list up down logs remove start stop restart dev hosts help"
    
    # Get projects from docker-compose.yml
    if [ -f "$HOME/.timonel-path" ]; then
        TIMONEL_DIR=$(cat "$HOME/.timonel-path")
    else
        TIMONEL_DIR="$HOME/projects/timonel"
    fi
    
    # Shared helper (run in a separate bash so its functions don't leak
    # into your shell): project services only, no core services or network
    if [ -f "$TIMONEL_DIR/docker-compose.yml" ]; then
        projects=$(cd "$TIMONEL_DIR" && \
                   bash -c 'source scripts/lib/compose.sh && list_project_services' 2>/dev/null || true)
    fi
    
    case "${prev}" in
        timonel)
            COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
            return 0
            ;;
        new)
            COMPREPLY=($(compgen -W "nextjs wp vite parcel laravel" -- ${cur}))
            return 0
            ;;
        open|logs|remove|start|stop|restart|dev)
            COMPREPLY=($(compgen -W "${projects}" -- ${cur}))
            return 0
            ;;
        add)
            # Folders in apps/ that aren't registered yet
            local unregistered
            unregistered=$(cd "$TIMONEL_DIR" 2>/dev/null && \
                bash -c 'source scripts/lib/project.sh && source scripts/lib/compose.sh && list_unregistered_apps' 2>/dev/null || true)
            COMPREPLY=($(compgen -W "${unregistered}" -- ${cur}))
            return 0
            ;;
    esac
}

complete -F _timonel_completions timonel