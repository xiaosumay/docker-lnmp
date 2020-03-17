#!/bin/bash
set -e

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname $SCRIPT)"
pushd $SCRIPT_PATH 1>&2 2>/dev/null || exit 1

#启用自建的一些方便函数
. $SCRIPT_PATH/work/tools/functions.sh

#判断是否有root的权限
if ! HasRootPremission; then
    if IsCommandExists sudo; then
        sudo bash "$0"
        exit $?
    else
        ray_echo_Red "ERROR: You need to be root to run this script"
    fi
fi

#很重要，需要一些环境变量
if ! IsFile ${SCRIPT_PATH}/.env; then
    cp ${SCRIPT_PATH}/.env.sample ${SCRIPT_PATH}/.env;
    ray_echo_Red "please modify ${SCRIPT_PATH}/.env first!";
    exit 1
fi

. ${SCRIPT_PATH}/.env
ray_printStatusOk "导入.env环境变量"

#国内知名的仓库源
mirrors=(
        #阿里内网
        mirrors.cloud.aliyuncs.com
        #阿里公网
        mirrors.aliyun.com
    )

#因为我司服务器都是在aliyun上，所以优先使用aliyun的内部网络
for mirrors_ in "${mirrors[@]}"; do
    if nc -z -w 1 $mirrors_ 80 1>&2 2>/dev/null; then
        mirrors_default=$mirrors_
    fi
done

ray_echo_Green "探测到仓库源 ${mirrors_default}"

if ! IsCommandExists docker; then
    if IsUbuntu; then
        apt-get update -y
        apt-get remove docker docker-engine docker.io containerd runc -y
        apt-get install apt-transport-https ca-certificates curl gnupg-agent \
            software-properties-common -y

        curl -fsSL https://${mirrors_default}/docker-ce/linux/ubuntu/gpg | apt-key add -

        the_ppa="http://${mirrors_default}/docker-ce/linux/ubuntu"
        if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            add-apt-repository \
            "deb [arch=amd64 trusted=yes] $the_ppa $(lsb_release -cs)  stable"
        fi

        ray_printStatusOk "docker 仓库已更新"
    elif IsRedHat; then
        #centos7以上
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
        mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
        wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

        yum makecache -y
        yum remove docker docker-client docker-client-latest docker-common \
            docker-latest docker-latest-logrotate docker-logrotate docker-engine -y
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://${mirrors_default}/docker-ce/linux/centos/docker-ce.repo

        ray_printStatusOk "docker 仓库已更新"
    fi

    InstallApps docker-ce docker-ce-cli containerd.io  mysql-client-core-5.7 jq git htop iftop

    if IsCommandExists docker; then
        ray_printStatusOk "安装docker……"
    else
        ray_printStatusFailed "安装docker……"
        exit 1
    fi
fi


ray_echo_Green "检测docker-compose文件"
if ! IsFile /usr/local/bin/docker-compose; then
    ray_echo_Green "正在下载docker-compose，很慢的，稍安勿躁……"
    curl -fSL https://get.daocloud.io/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m) \
        -o /usr/local/bin/docker-compose  && chmod +x /usr/local/bin/docker-compose

    if ! IsSameStr "$(sha256sum /usr/local/bin/docker-compose | awk '{print $1 }')"  \
                    "cfb3439956216b1248308141f7193776fcf4b9c9b49cbbe2fb07885678e2bb8a" ; then
        ray_echo_Red "docker-compose 文件sha256不对"
        exit 1
    fi

    if IsCommandExists docker-compose; then
        ray_printStatusOk "安装docker-compose"
    else
        ray_printStatusFailed "安装docker-compose"
        exit 1
    fi
fi

#注入公用的docker-compose环境变量
. ${SCRIPT_PATH}/.env


if ! IsFileHasStr '#lnmp-tools' $HOME/.bashrc; then
    sed -i -e "\$a#lnmp-tools\n. $SCRIPT_PATH/work/tools/functions.sh\n" $HOME/.bashrc
    ray_printStatusOk "安装基本快捷bash命令"
fi

#配置logrotate，每天切割日志
if IsDir /etc/logrotate.d; then
    cat > /etc/logrotate.d/wwwlogs <<EOF
$SCRIPT_PATH/work/logs/*.log {
    su root root
    daily
    rotate 7
    missingok
    notifempty
    compress
    dateext
    sharedscripts
    postrotate
         /usr/bin/env docker exec nginx nginx -s reopen
    endscript
}
EOF
    chmod 644 /etc/logrotate.d/wwwlogs
    ray_printStatusOk "安装日志切割脚本"
fi

#删除可能存在的旧的的容器
docker-compose down --rmi local 2>/dev/null || true

################################生成数据库的密码#################################

if ! IsFile db_root_password.txt; then
    DB_ROOT_PASSWD="$(MakePassword)"
    DB_DEFAULT_PASSWD="$(MakePassword)"
    #这个是数据库root的密码
    echo -n "$DB_ROOT_PASSWD" > db_root_password.txt
    ray_printStatusOk "生成数据库root密码"
    #这个是项目要用的数据库用户密码
    echo -n "$DB_DEFAULT_PASSWD" > db_${MYSQL_USER}_password.txt
    ray_printStatusOk "生成数据库用户${MYSQL_USER}密码"

    chmod 400 db_root_password.txt
    chmod 444 db_${MYSQL_USER}_password.txt
fi

###############################恢复默认文件权限##################################
find $SCRIPT_PATH -type f -exec chmod 644 {} \;
find $SCRIPT_PATH -name "*.sh" -exec chmod 755 {} \;
find $SCRIPT_PATH -type d  -exec chmod 755 {} \;
chmod 777 work/logs
ray_printStatusOk "恢复默认文件权限"

###########################从本地添加docker-images###############################

#把文件docker-images.tar.gz放在/opt/docker-lnmp目录下
Images=""

if ! IsFile $Images; then
    Images="docker-images.tar.gz"
elif ! IsFile $Images; then
   Images="$HOME/docker-images.tar.gz"
fi

if ! IsEmpty $Images; then
    ray_echo_Green "正在使用本地docker-images"
    gzip -d "$Images"
    docker load -i "${Images%.tar.gz}"

    if ! IsEmpty $DOCKER_LOCAL_SRC; then
        for image in "code-get:2.0" "php7.3-fpm" "php7.3-cli" \
                     "nginx-with-lua:1.16.0" "redis:5.0" "mysql:5.7"; do
            docker tag xiaosumay/$image  ${DOCKER_LOCAL_SRC}xiaosumay/$image
        done
    fi
    ray_printStatusOk "安装lnmp成功"
fi
################################################################################

ray_echo_Green "正在启动服务"

docker-compose up -d

rm -f "$SCRIPT"

popd 1>&2 2>/dev/null

ray_printStatusOk "docker-lnmp 安装……"
