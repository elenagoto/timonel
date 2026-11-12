#compdef timonel

_timonel() {
    local curcontext="$curcontext" state line ret=1
    typeset -A opt_args
    local -a projects

    # Get timonel directory
    if [ -f "$HOME/.timonel-path" ]; then
        TIMONEL_DIR=$(cat "$HOME/.timonel-path")
    else
        TIMONEL_DIR="$HOME/projects/timonel"
    fi

    # Get projects
    # Shared helper (run in bash, the scripts' shell): project services
    # only, no core services or network
    if [ -f "$TIMONEL_DIR/docker-compose.yml" ]; then
        projects=(${(f)"$(cd "$TIMONEL_DIR" && \
                         bash -c 'source scripts/lib/compose.sh && list_project_services' 2>/dev/null)"})
    fi

    local -a commands
    commands=(
        'new:Create new project'
        'add:Dockerize an existing project in apps/'
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
        'history:Recent commands (--errors: failed ones)'
        'help:Show help'
    )

    local -a types
    types=(
        'nextjs:Next.js project'
        'wp:WordPress project'
        'vite:Vite React project'
        'parcel:Parcel project'
        'laravel:Laravel project'
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
                add)
                    # Folders in apps/ that aren't registered yet
                    local -a unregistered
                    unregistered=(${(f)"$(cd "$TIMONEL_DIR" 2>/dev/null && \
                        bash -c 'source scripts/lib/project.sh && source scripts/lib/compose.sh && list_unregistered_apps' 2>/dev/null)"})
                    _describe 'folder' unregistered && ret=0
                    ;;
            esac
            ;;
    esac

    return ret
}

_timonel "$@"