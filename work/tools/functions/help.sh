function docker-lnmp-help() {
cat <<EOF
常用操作命令说明书

wwwlogs     去往日志目录
wwwroot     打开项目文件路径

VimVhost    编辑或生成项目nginx配置
            用法：VimVhost <项目名> <端口号> <所用框架[thinkphp|laravel]>
            创建：VimVhost bankpay 80 thinkphp
            编辑：VimVhost bankpay

nginx-reload    编辑完nginx配置后重新加载


SystemdEnable   加载service
                用法：SystemdEnable <path-to-service>/AutoOrder.service

MakeService     生成thinkphp的service
                用法：MakeService <project-name> <command-name> [interval]
                例如：MakeService bankpay AutoOrder 20
MakeTimer       生成thinkphp的timer
                用法：MakeTimer <project-name> <command-name> <calendar>
                例如：MakeTimer bankpay AutoOrder "00:30:00"

ss  启动service，via systemctl start <service-name>
    用法 ss AutoOrder.service
sp  停止service，via systemctl stop <service-name>
    用法 sp AutoOrder.service
sl  重新加载service，via systemctl reload <service-name>
    用法 sl AutoOrder.service
sr  重启service，via systemctl restart <service-name>
    用法 sr AutoOrder.service
st  查看service状态，via systemctl status <service-name>
    用法 st AutoOrder.service
jo  查看service日志，via journalctl -f -u <service-name>
    用法 jo AutoOrder.service


AddFirewallPorts 添加防火墙准入端口，前提防火墙开启
                ubuntu:  sudo ufw enable
                Centos7: sudo systemctl start firewalld
                用法：addFirewallPorts [port] ...
                例如: addFirewallPorts 22 80 443 46832 17293

code-get    更新所以项目文件
            用法：code-get

git-log     查看项目git日志
            用法：git-log <项目名>
            例如：git-log default
EOF
}
