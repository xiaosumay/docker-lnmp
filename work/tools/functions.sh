#!/bin/bash

export RAY_SCRIP_FILE_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export LNMP_WORK_FILE_PATH=$(readlink -f $RAY_SCRIP_FILE_PATH/../)

if [[ -f $LNMP_ROOT_PATH/.env ]]; then
    . $LNMP_ROOT_PATH/.env || true
fi

for file in `find $RAY_SCRIP_FILE_PATH  -mindepth 2 -not -regex ".*/extras/.*?$" -a -name "*.sh"`; do
    . $file
done

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
