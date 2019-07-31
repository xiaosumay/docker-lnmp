#######################################
# test a arg is a empty str
# eg: IsEmpty ''
#
#######################################
function IsEmpty() {
    if [ -z "$1" ]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

#######################################
# test a arg is a empty str
# eg: IsEmpty ''
#######################################
function IsSameStr() {
    if [ "$1" = "$2" ]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

function HasRootPremission() {
    if [ "$(id -u)" != "0" ]; then
        return $RAY_RET_FAILED
    fi

    return $RAY_RET_SUCCESS
}

if ! HasRootPremission; then
    RAY_SUDO=sudo
fi

#######################################
# test if a commond is existed
# eg: IsCommandExists git
# if the command git is not exited,
# then it will return not 0 value
#######################################
function IsCommandExists() {
    local CMDS
    for cmd in "$@"; do
        if ! type $cmd >/dev/null 2>&1; then
            CMDS="$CMDS $cmd"
        fi
    done

    if [ ! -z "$CMDS" ]; then
        return $RAY_RET_FAILED
    fi

    return $RAY_RET_SUCCESS
}

if IsCommandExists vim; then
    RAY_EDIT=vim
    elif IsCommandExists vi; then
    RAY_EDIT=vi
    elif IsCommandExists nano; then
    RAY_EDIT=nano
fi

function IsDir() {
    if [ -d "$1" ]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

function IsFile() {
    if [ -f "$1" ]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

#######################################
# create a dir with owner is cur user
# eg: CreateDir /tmp/haha
#######################################
function CreateDir() {
    if ! IsDir $1; then
        $RAY_SUDO mkdir -p $1
        $RAY_SUDO chown `whoami`:`whoami` $1
    fi

    IsDir $1
    return $?
}

function CreateFile() {
    if ! IsFile $1; then
        $RAY_SUDO mkdir -p $(dirname $1)
        $RAY_SUDO touch $1
        $RAY_SUDO chown `whoami`:`whoami` $1
    fi

    IsFile $1
    return $?
}

#######################################
# make a random str
# @param width default is 30
#######################################
function MakePassword() {
    if type openssl 2>&1 1>/dev/null; then
        openssl rand -base64 18 2>/dev/null
    else
        head /dev/urandom | tr -dc 'a-zA-Z0-9/\-=[];,._+{}:<>@%^&*()' | fold -w ${1:-18} | head -n 1
    fi
}

function IsZsh() {
    if [[ `ps -p $$ -oargs=` =~ "zsh" ]]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

function IsBash() {
    if [[ `ps -p $$ -oargs=` =~ "bash" ]]; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}

function IsFileHasStr() {
    if ! IsFile "$2"; then
        return $RAY_RET_FAILED
    fi

    if $RAY_SUDO grep -Eqi "$1" "$2"; then
        return $RAY_RET_SUCCESS
    fi

    return $RAY_RET_FAILED
}
