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
    # Shared helper (run in bash, the scripts' shell): project services
    # only, no core services or network
    if [ -f "$DOCKERATOR_DIR/docker-compose.yml" ]; then
        projects=(${(f)"$(cd "$DOCKERATOR_DIR" && \
                         bash -c 'source scripts/lib/compose.sh && list_project_services' 2>/dev/null)"})
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
        'dev:Open a dev shell in a project'
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
                open|logs|remove|start|stop|restart|dev)
                    _describe 'project' projects && ret=0
                    ;;
            esac
            ;;
    esac

    return ret
}

_dockerator "$@"