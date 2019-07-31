# Docker LNMP

Docker LNMP 可以构建出基于 Docker 的 PHP 开发环境，其优势有在短时间内随意构建不同版本的相关服务、环境统一分布在不同服务器等，使开发者能够更专注于开发业务本身。

# 初始化
- 执行`./init.sh`，然后可能有输出红色`please modify .env first!`
  - 修改`.env`文件相关参数

  |参数名|注释|
  |:----------|:------|
  |`COMPOSE_PROJECT_NAME`|项目名，默认是`lnmp` |
  |`DOCKER_LOCAL_SRC`|`docker`资源国内代理，默认是`dockerhub.azk8s.cn/`，不用则为|
  |`HTTP_PORT`|`nginx`容器`80`端口导出端口|
  |`HTTPS_PORT`|`nginx`容器`443`端口导出端口|
  |`MYSQL_USER`|项目的对应数据库的用户名|
  |`MYSQL_DATABASE`|项目所用到的数据库名|
  |`MYSQL_PORT`|`mysql`容器`3306`端口导出端口|
  |`REDIS_PORT`|`redis`容器`6379`端口导出端口|

  -重新执行`./init.sh`，安装环境

- 执行`./repos.sh`，配置`github`仓库
  - 使用方式
    * `./repos.sh <项目名> <项目所在服务器ip> [<项目负责人github用户名> [<项目负责人github用户名>]] `
    * 例如：`./repos.sh xplayer 127.0.0.1  haha_1 haha_2`

- 开放服务器防火墙
  - `$HTTP_PORT 和 $HTTPS_PORT` nginx对外端口
  - `17293/tcp` github webhook的响应端口

- 在项目负责人的电脑上拉取项目，编辑并`push`，则服务代码自动拉取更新
