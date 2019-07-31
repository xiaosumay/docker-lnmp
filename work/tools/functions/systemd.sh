function SystemdEnable() {
    local service_name
    local _status
    for service in "$@"; do
        service_name=$(basename $service)
        _status=$(ray_none_output systemctl status $service_name | grep Loaded | awk '{print $2}')

        if [ "$_status" = 'loaded' ]; then
            echo -n "loaded from: "
            $RAY_SUDO systemctl status $1 | grep Loaded | awk '{print $3}' | tr -d '();'
        else
            echo "created from: $(readlink -f "$service")"
            ray_none_output $RAY_SUDO systemctl enable -f "$(readlink -f "$service")"
        fi
    done
}

function clearBrokenLinks() {
    if [ ! -d /etc/systemd/system ]; then
        return $RAY_RET_SUCCESS
    fi

    for line in `find /etc/systemd/system -type l -print0 | xargs -n 1 file \
                        | grep 'broken symbolic link' | awk  -F':' '{print $1}'`; do
        $RAY_SUDO rm -f $line
    done
}

function SystemdDisable() {
    local service_name
    local _status
    for service in "$@"; do
        service_name=$(basename $service)
        _status=$(systemctl status $service_name 2>/dev/null | grep Loaded | awk '{print $2}')
        if [ "$_status" = 'loaded' ]; then
            if IsServiceActive $service_name; then
                $RAY_SUDO systemctl stop $service_name
            fi

            ray_none_output $RAY_SUDO systemctl disable $service_name
        fi

        echo "remove from: $service_name"
    done

    clearBrokenLinks

    return $RAY_RET_SUCCESS
}

#active inactive
function IsServiceActive() {
    local active=$(systemctl is-active $1)

    if [ "$active" = "active" ]; then
        return $RAY_RET_SUCCESS
    else
        return $RAY_RET_FAILED
    fi
}

function MakeService() {
    if IsSameStr "$1" "--help"; then
        echo "uesage: MakeService <project-name> <command-name> [interval]"
        echo "        MakeService bankpay AutoOrder 20"
    fi
    local project_name="$1"
    shift || {
        ray_echo_Red "project name"
        return $RAY_RET_FAILED
    }

    local command_name="$1"
    shift || {
        ray_echo_Red "command name"
        return $RAY_RET_FAILED
    }

    local interval=$1

    local service_type="simple"
    local service_restart="Restart=always"
    local command_str="while true; do php think $command_name; sleep $interval; done"
    if IsEmpty "$interval"; then
        service_type="oneshot"
        service_restart=""
        command_str="php think $command_name;"
    fi

    cat > $command_name.service <<EOF
[Unit]
Description=$command_name
BindsTo=docker.service
Requisite=docker.service

[Service]
WorkingDirectory=/opt/docker-lnmp
ExecStart=/opt/docker-lnmp/php-cli-entrypoint.sh "$project_name" "$command_name" bash -c "$command_str"
ExecStop=/bin/bash -c "/usr/bin/docker stop --time=1 $command_name || true"
TimeoutStopSec=30s
Type=$service_type
$service_restart

[Install]
WantedBy=multi-user.target
EOF
}

function MakeTimer() {
    if IsSameStr "$1" "--help"; then
        echo "uesage: MakeTimer <project-name> <command-name> <calendar>"
        echo "        MakeTimer bankpay HeardBeatLine 00:03:00"
    fi
    local project_name="$1"

    shift || {
        ray_echo_Red "command name"
        return $RAY_RET_FAILED
    }
    local command_name="$1"

    shift || {
        ray_echo_Red "calendar"
        return $RAY_RET_FAILED
    }
    local calendar=$1

    if IsEmpty "$calendar"; then
        ray_echo_Red "calendar"
        return $RAY_RET_FAILED
    fi

    cat > $command_name.timer <<EOF
[Unit]
Description=$command_name

[Timer]
OnCalendar=$calendar

[Install]
WantedBy=timers.target
EOF

    MakeService "$project_name" "$command_name"
}
