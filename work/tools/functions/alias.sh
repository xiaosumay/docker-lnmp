function nginx() {
    if IsCommandExists docker; then
        docker exec nginx nginx "$@"
    else
        $RAY_SUDO nginx "$@"
    fi
}

function nginx-reload() {
    nginx -t && nginx -s reload
}

function lnmctl() {
    if IsCommandExists docker-compose; then
        pushd $LNMP_ROOT_PATH 1>/dev/null 2>/dev/null || return
        docker-compose "$@"
        popd  1>/dev/null 2>/dev/null || return
    else
        ray_echo_Red "do nothing..."
    fi
}

function code-get() {
    if IsCommandExists docker; then
        docker exec code-get code-get -u
    fi
}

function wwwroot() {
    if [[ ! -x $LNMP_ROOT_PATH/php-cli-entrypoint.sh ]]; then
        $RAY_SUDO chmod +x $LNMP_ROOT_PATH/php-cli-entrypoint.sh
    fi

    $LNMP_ROOT_PATH/php-cli-entrypoint.sh "$@"
}

function wwwlogs() {
    cd $LNMP_LOG_ROOT_PATH  2>/dev/null || return 1
}

function mypublicip() {
    curl ifconfig.me 2>/dev/null | xargs echo
}

function findFastMirror() {
     curl -s http://mirrors.ubuntu.com/mirrors.txt | \
     xargs -n1 -I {} sh -c 'echo `curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz` {}' | \
     sort -g -r | head -1 | awk '{ print $2  }'
 }

function docker-lnmp() {
    cd $LNMP_ROOT_PATH  2>/dev/null || return 1
}

function ss() {
    for service_ in "$@"; do
        local SERVICE=$(basename $service_)

        if IsCommandExists systemctl; then
            $RAY_SUDO systemctl start "$SERVICE" || return 1
        else
            $RAY_SUDO service "$SERVICE" start || return 1
        fi
    done
}

function sl() {
    if IsCommandExists systemctl; then
        $RAY_SUDO systemctl daemon-reload
    fi

    for service_ in "$@"; do
        local SERVICE=$(basename $service_)
        if IsCommandExists systemctl; then
            $RAY_SUDO systemctl reload "$SERVICE" || return 1
        else
            $RAY_SUDO service "$SERVICE" reload || return 1
        fi
    done
}

function sr() {
    if IsCommandExists systemctl; then
        $RAY_SUDO systemctl daemon-reload
    fi

    for service_ in "$@"; do
        local SERVICE=$(basename $service_)
        if IsCommandExists systemctl; then
            $RAY_SUDO systemctl restart "$SERVICE" || return 1
        else
            $RAY_SUDO service "$SERVICE" restart || return 1
        fi
    done
}

function sp() {
    for service_ in "$@"; do
        local SERVICE=$(basename $service_)

        if IsCommandExists systemctl; then
            $RAY_SUDO systemctl stop "$SERVICE" || return 1
        else
            $RAY_SUDO service "$SERVICE" stop || return 1
        fi
    done
}

function st() {
    for service_ in "$@"; do
        local SERVICE=$(basename $service_)

        if IsCommandExists systemctl; then
            $RAY_SUDO systemctl status "$SERVICE" || return 1
        else
            $RAY_SUDO service "$SERVICE" status || return 1
        fi
    done
}

function jo() {
    for service_ in "$@"; do
        local SERVICE=$(basename $service_)

        if IsCommandExists journalctl; then
            $RAY_SUDO journalctl -n30 -f -u "$SERVICE" || return 1
        fi
        break
    done
}

alias ll="ls -laFh"
alias php-cli-entrypoint="$LNMP_ROOT_PATH/php-cli-entrypoint.sh"
alias gundan="pkill -kill -t"

function pause() {
    local key
    read -n1 -r -p "Press any key to continue..." key
    return $RAY_RET_SUCCESS
}

function git-log() {
    local project_path="$(basename "$1")"

    if pushd /var/lib/docker/volumes/${COMPOSE_PROJECT_NAME}_wwwroot/_data/$project_path 1>/dev/null 2>/dev/null; then
        [[ -d ".git" ]] && git log
        popd
    elif pushd $LNMP_ROOT_PATH/work/wwwroot/$project_path 1>/dev/null 2>/dev/null; then
        [[ -d ".git" ]] && git log
        popd
    fi
}

function clean-docker-log {
    for name in `docker container ls --format "{{json .Names}}" | tr -d '"'`; do
        $RAY_SUDO docker inspect $name -f "{{.LogPath}}" | xargs -n1 truncate -s 0;
    done
}

alias JQ_MATCH_4XX="jq 'select(.status | match(\"4..\")) | .'"
alias JQ_MATCH_5XX="jq 'select(.status | match(\"5..\")) | .'"
alias JQ_MATCH_NOT_200="jq 'select((.status != \"200\") and (.status | match(\"[^3]..\"))) | .'"
alias JQ_MATCH_UNDEFINED_PHP="jq 'select(.request | match(\"\\\\.php\")) | .'"
