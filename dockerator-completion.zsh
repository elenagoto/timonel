#compdef dockerator

_dockerator() {
    local curcontext="$curcontext" state line ret=1
    typeset -A opt_args
    local -a projects

    # Get dockerator directory
    if [ -f "$HOME/.dockerator-path" ]; then
        DOCKERATOR_DIR=$(cat "$HOME/.dockerator-path")
    else
        DOCKERATOR_DIR="$HOME/projects/dockerator"
    fi

    # Get projects
    if [ -f "$DOCKERATOR_DIR/docker-compose.yml" ]; then
        projects=(${(f)"$(grep -E "^  [a-z0-9-]+:" "$DOCKERATOR_DIR/docker-compose.yml" | \
                         sed 's/://g' | sed 's/^  //' | \
                         grep -v "traefik\|mysql\|adminer\|mailpit")"})
    fi

    local -a commands
    commands=(
        'new:Create new project'
        'open:Open project in VS Code'
        'list:List all projects'
        'up:Start all containers'
        'down:Stop all containers'
        'logs:View project logs'
        'remove:Remove project'
        'start:Start specific project'
        'stop:Stop specific project'
        'restart:Restart with full dependency reinstall'
        'dev-wp:WordPress dev mode'
        'dev-nextjs:Next.js dev mode'
        'dev-vite:Vite dev mode'
        'dev-front:Frontend dev mode'
        'hosts:Sync /etc/hosts'
        'help:Show help'
    )

    local -a types
    types=(
        'nextjs:Next.js project'
        'wp:WordPress project'
        'vite:Vite React project'
        'parcel:Parcel project'
    )

    _arguments -C \
        '1: :->command' \
        '2: :->argument' \
        && ret=0

    case $state in
        command)
            _describe 'command' commands && ret=0
            ;;
        argument)
            case $words[2] in
                new)
                    _describe 'type' types && ret=0
                    ;;
                open|logs|remove|start|stop|restart|dev-wp|dev-nextjs|dev-vite|dev-front)
                    _describe 'project' projects && ret=0
                    ;;
            esac
            ;;
    esac

    return ret
}

_dockerator "$@"