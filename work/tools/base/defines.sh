#function return value if success
export RAY_RET_SUCCESS=0
#function return value if failed
export RAY_RET_FAILED=1
#when an instance startup, all log will be send to new file
unset RAY_LOG_FILE

if [ -z "$NGINX_VHOST_CONF_PATH" ]; then
    export NGINX_VHOST_CONF_PATH=$LNMP_WORK_FILE_PATH/nginx/vhost
fi

if [ -z "$NGINX_NGINX_CONF_PATH" ]; then
    export NGINX_NGINX_CONF_PATH=$LNMP_WORK_FILE_PATH/nginx/nginx.conf
fi

if [ -z "$LNMP_DOC_ROOT_PATH" ]; then
    export LNMP_DOC_ROOT_PATH=$LNMP_WORK_FILE_PATH/wwwroot
fi

if [ -z "$LNMP_LOG_ROOT_PATH" ]; then
    export LNMP_LOG_ROOT_PATH=$LNMP_WORK_FILE_PATH/logs
fi

if [ -z "$LNMP_ROOT_PATH" ]; then
    export LNMP_ROOT_PATH=$LNMP_WORK_FILE_PATH/../
fi
