function mkTemplateVHost() {
    local plugin=thinkphp

    if [[ "$4" = "yii" || "$4" = "yii2" ]]; then
        plugin=yii2
    else
        plugin=${4:-thinkphp}
    fi

    if ! IsEmpty $plugin; then
        plugin="include conf.d/rewrite/$plugin.conf;";

    else
        plugin=<<EOF

    location / {
        try_files \$uri \$uri/ index.php\$request_uri;
    }
EOF
    fi

    $RAY_SUDO touch $1
    $RAY_SUDO chown `whoami`:`whoami` $1
    cat > $1 <<EOF
# upstream gunicorn_backend {
# 	server gunicorn:8000;
# 	keepalive 16;
# }

server {
    include conf.d/lua_core.conf;
    include conf.d/limits.conf;

    listen ${3:-80};
    index index.html index.htm index.php;
    root /var/www/html/$2/public;
    server_name _;

    $plugin

    expires \$expires;

    # location / {
    #    include conf.d/proxy.conf;
    #    proxy_pass http://gunicorn_backend;
    #}

    location = /lua {
        set \$loggable 0;
        default_type text/html;
        content_by_lua 'ngx.say("hello world")';

        include conf.d/lua/must_be_human.conf;
    }

    access_log  /var/log/nginx/access.${2:-default}.log json_log buffer=8k flush=10s if=\$loggable;
    error_log   /var/log/nginx/error.${2:-default}.log  warn;
}
EOF
    $RAY_SUDO chmod 644 $1
    $RAY_SUDO chown 1000:999 $1
}

function CountAccessIP() {
    if [ $# -eq 0 ]; then
        ray_echo_Red "useage: $0 [vhost] [lines]"
        return $RAY_RET_FAILED
    fi

    if IsFile $LNMP_LOG_ROOT_PATH/access.$1.log; then
        cat $LNMP_LOG_ROOT_PATH/access.$1.log | jq ".realip" | sort | uniq -c | sort -rn | head -n ${2:-10}
    fi
}

function VimVHost() {
    if [[ "$1" = "-h" || "$1" = "--help" ]] || IsEmpty "$1"; then
        echo "useage: CreateVHost [filename] [port] [frame]"
        return $RAY_RET_FAILED
    fi

    local vhost_path=${NGINX_VHOST_CONF_PATH:-/usr/local/nginx/conf/vhost}

    if ! IsDir $vhost_path; then
        return $RAY_RET_FAILED
    fi

    local vhost=${vhost_path}/$1.conf

    if IsSameStr "$1" "nginx"; then
        vhost=$NGINX_NGINX_CONF_PATH
    fi

    if ! IsFile $vhost; then
        read -r -p "new host? [Y/n]:" confirm

        case $confirm in
            Y|y)
                mkTemplateVHost $vhost "$@"
            ;;
            * ) return $RAY_RET_FAILED ;;
        esac
    fi

    $RAY_SUDO $RAY_EDIT $vhost

    if IsCommandExists nginx; then
        local confirm
        read -r -p "reload nginx conf ? [Y/n]:" confirm

        case $confirm in
            Y|y)
                nginx -t && nginx -s reload
            ;;
            * ) return $RAY_RET_SUCCESS ;;
        esac
    fi

    return $RAY_RET_SUCCESS
}

function ListVHosts() {
    local conf
    local port
    local server_name
    local vhost_path=${NGINX_VHOST_CONF_PATH:-/usr/local/nginx/conf/vhost}

    if ! IsDir $vhost_path; then
        return $RAY_RET_FAILED
    fi

    for conf in $vhost_path/*.conf; do
        port=` grep 'listen' $conf | awk '{print $2}' | tr "\n;" ' '`
        server_name=`grep 'server_name' $conf | awk '{$1=""; print $0}' | tr "\n;" ' '`
        printf "WebHost: %-20s \nport: %s \nserver_name: %s\n\n" "$(basename ${conf%.conf})" "$port" "$server_name"
    done

    return $RAY_RET_SUCCESS
}
