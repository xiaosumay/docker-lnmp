#!/bin/bash

export RAY_SCRIP_FILE_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export LNMP_WORK_FILE_PATH=$(readlink -f $RAY_SCRIP_FILE_PATH/../)

export __exit_trap_command=""
function __cleanup {
    eval "$__exit_trap_command"
}

trap __cleanup EXIT

function add_exit_trap {
    local to_add="$*"

    if [[ -z "$__exit_trap_command" ]]; then
        __exit_trap_command="$to_add"
    else
        __exit_trap_command="$__exit_trap_command; $to_add"
    fi
}

for file in `find $RAY_SCRIP_FILE_PATH  -mindepth 2 -not -regex ".*/extras/.*?$" -a -name "*.sh"`; do
    . $file
done

if [[ -f $LNMP_ROOT_PATH/.env ]]; then
    . $LNMP_ROOT_PATH/.env || true
fi

function ShowFunctions() {
    local width=`tput cols`
    local step=`expr $width / 25`

    local my_type='A-Z'
    if [ "$1" = "all" ]; then
        my_type='A-Za-z'
    fi

    for file in `find $RAY_SCRIP_FILE_PATH/functions -not -regex ".*/extras/.*?$" -a -name "*.sh" -print | sort`; do
        local num=1
        local name=$file
        name=${name//$RAY_SCRIP_FILE_PATH\//}
        name=${name//.sh/}
        name=${name//\//.}

        echo "$name:"
        for func in `cat $file | grep -Eo " [$my_type](.*?)\(\) " | tr -d '()' | sort`; do
            printf "%-22s" $func
            if (( $num % $step )); then
                echo -en "\t"
            else
                echo -en "\n"
            fi
            num=`expr $num + 1`
        done

        echo -en "\n"
    done
}

function clearup_docker() {
    for name in `$RAY_SUDO docker container ls --format '{{json .Names}}' | tr -d '"' | grep "^oneshot_"`; do
        $RAY_SUDO docker container stop --time=1 $name 2>/dev/null || true
    done
}

add_exit_trap clearup_docker
