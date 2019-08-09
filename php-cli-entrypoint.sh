#!/bin/bash
set -e
if [[ $(id -u) -ne 0 ]]; then
    if type sudo 2>&1 >/dev/null; then
        sudo bash "$0" "$@"
        exit $?
    else
        ray_echo_Red "ERROR: You need to be root to run this script"
        exit 1
    fi
fi

SCRIPT_PATH="$(dirname $(readlink -f "$0"))"
pushd $SCRIPT_PATH 2>&1 >/dev/null

dir_name=${1:-.}
shift || true

if [[ "$dir_name" == "--help" ]]; then
    cat << EOF
useage: $(basename "$0") [dir-name-sub-wwwroot] project_name command arg1 arg2...

composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/
composer config -g repo.packagist composer https://packagist.phpcomposer.com
composer config -g repo.packagist composer https://packagist.laravel-china.org
EOF
    exit 0
fi

project_name=${1:-"oneshot_${SSH_BASH_PID}_$(head /dev/urandom | tr -dc 'a-zA-Z' | fold -w 10 | head -n 1)"}
shift || true

if [[ $# -eq 0 ]]; then
    IT=-it
    COMMAND=bash
fi

. $SCRIPT_PATH/.env

function cleanup() {
    docker container stop --time=1 ${project_name} 1>&2 2>/dev/null || true
}

#注册退出清理工作
trap cleanup EXIT

docker run $IT --rm \
    -v ${COMPOSE_PROJECT_NAME}_wwwroot:/var/www/html:rw \
    -v ${COMPOSE_PROJECT_NAME}_composer:/var/www/.composer:rw \
    -v /etc/localtime:/etc/localtime:ro \
    -v $SCRIPT_PATH/work/php/php.ini:/usr/local/etc/php/php.ini:ro \
    -w /var/www/html/$dir_name \
    --dns 114.114.114.114 --dns 8.8.8.8 --dns 8.8.4.4 \
    --user 1000:999 \
    --network host \
    --name ${project_name} \
    ${DOCKER_LOCAL_SRC}xiaosumay/php7.3-cli \
    ${COMMAND:-"$@"}
