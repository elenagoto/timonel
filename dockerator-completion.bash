#!/bin/bash
# Bash completion for dockerator
# Install: sudo cp dockerator-completion.bash /etc/bash_completion.d/dockerator

_dockerator_completions() {
    local cur prev commands projects
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    commands="new open list up down logs remove start stop restart dev-wp dev-nextjs dev-vite dev-front hosts help"
    
    # Get projects from docker-compose.yml
    if [ -f "$HOME/.dockerator-path" ]; then
        DOCKERATOR_DIR=$(cat "$HOME/.dockerator-path")
    else
        DOCKERATOR_DIR="$HOME/projects/dockerator"
    fi
    
    if [ -f "$DOCKERATOR_DIR/docker-compose.yml" ]; then
        projects=$(grep -E "^  [a-z0-9-]+:" "$DOCKERATOR_DIR/docker-compose.yml" | \
                   sed 's/://g' | sed 's/^  //' | \
                   grep -v "traefik\|mysql\|adminer\|mailpit" || true)
    fi
    
    case "${prev}" in
        dockerator)
            COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
            return 0
            ;;
        new)
            COMPREPLY=($(compgen -W "nextjs wp vite parcel" -- ${cur}))
            return 0
            ;;
        open|logs|remove|start|stop|restart|dev-wp|dev-nextjs|dev-vite|dev-front)
            COMPREPLY=($(compgen -W "${projects}" -- ${cur}))
            return 0
            ;;
    esac
}

complete -F _dockerator_completions dockerator